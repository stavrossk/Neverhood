/*
// Smacker decoder
// Based heavily on the ScummVM v1.3.1 Smacker decoder (video/smkdecoder.h)
// https://github.com/scummvm/scummvm/tree/42ab839dd6c8a1570b232101eb97f4e54de57935/video
*/

#ifndef __SMACKER_DECODER_XS__
#define __SMACKER_DECODER_XS__

#undef NDEBUG
#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <memory.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

/*
// class BitStream
// Little-endian bit stream provider.
*/

typedef struct {
	Uint8* _buf;
	Uint8* _end;
	Uint8  _curByte;
	Uint8  _bitCount;
} BitStream;

static BitStream* BitStream_new(Uint8* buf, Uint32 length) {
	BitStream* this = safemalloc(sizeof(BitStream));
	this->_buf = buf;
	this->_end = buf + length;
	this->_bitCount = 8;
	this->_curByte = *this->_buf++;

	return this;
}

static bool BitStream_getBit(BitStream* this) {
	if (this->_bitCount == 0) {
		assert(this->_buf < this->_end);
		this->_curByte = *this->_buf++;
		this->_bitCount = 8;
	}

	bool v = this->_curByte & 1;

	this->_curByte >>= 1;
	this->_bitCount--;

	return v;
}

static Uint8 BitStream_get8(BitStream* this) {
	assert(this->_buf < this->_end);

	Uint8 v = (*this->_buf << this->_bitCount) | this->_curByte;
	this->_curByte = *this->_buf++ >> (8 - this->_bitCount);

	return v;
}

static Uint8 BitStream_peek8(BitStream* this) {
	if (this->_buf == this->_end)
		return this->_curByte;

	assert(this->_buf < this->_end);
	return (*this->_buf << this->_bitCount) | this->_curByte;
}

static void BitStream_skip(BitStream* this, int n) {
	assert(n <= 8);
	this->_curByte >>= n;

	if (this->_bitCount >= n) {
		this->_bitCount -= n;
	} else {
		assert(this->_buf < this->_end);
		this->_bitCount = this->_bitCount + 8 - n;
		this->_curByte = *this->_buf++ >> (8 - this->_bitCount);
	}
}

/*
// class SmallTree
// A Huffman-tree to hold 8-bit values.
*/

static const Uint16 SMK_SMALL_NODE = 0x8000;

typedef struct {
	Uint16 _treeSize;
	Uint16 _tree[511];

	Uint16 _prefixtree[256];
	Uint8 _prefixlength[256];

	BitStream* _bs;
} SmallTree;

static Uint16 SmallTree_decodeTree(SmallTree* this, Uint32 prefix, int length);

static SmallTree* SmallTree_new(BitStream* bs) {
	SmallTree* this = safemalloc(sizeof(SmallTree));
	this->_treeSize = 0;
	this->_bs = bs;

	bool bit = BitStream_getBit(bs);
	assert(bit);

	int i;
	for (i = 0; i < 256; i++)
		this->_prefixtree[i] = this->_prefixlength[i] = 0;

	SmallTree_decodeTree(this, 0, 0);

	bit = BitStream_getBit(bs);
	assert(!bit);

	return this;
}

static Uint16 SmallTree_decodeTree(SmallTree* this, Uint32 prefix, int length) {
	if (!BitStream_getBit(this->_bs)) { // Leaf
		this->_tree[this->_treeSize] = BitStream_get8(this->_bs);

		if (length <= 8) {
			int i;
			for (i = 0; i < 256; i += (1 << length)) {
				this->_prefixtree[prefix | i] = this->_treeSize;
				this->_prefixlength[prefix | i] = length;
			}
		}
		this->_treeSize++;

		return 1;
	}

	Uint16 t = this->_treeSize++;

	if (length == 8) {
		this->_prefixtree[prefix] = t;
		this->_prefixlength[prefix] = 8;
	}

	Uint16 r1 = SmallTree_decodeTree(this, prefix, length + 1);

	this->_tree[t] = SMK_SMALL_NODE | r1;

	Uint16 r2 = SmallTree_decodeTree(this, prefix | (1 << length), length + 1);

	return r1 + r2 + 1;
}

static Uint16 SmallTree_getCode(SmallTree* this, BitStream* bs) {
	Uint8 peek = BitStream_peek8(bs);
	Uint16* p = &this->_tree[this->_prefixtree[peek]];
	BitStream_skip(bs, this->_prefixlength[peek]);

	while (*p & SMK_SMALL_NODE) {
		if (BitStream_getBit(bs))
			p += *p & ~SMK_SMALL_NODE;
		p++;
	}

	return *p;
}

/*
// class BigTree
// A Huffman-tree to hold 16-bit values.
*/

static const Uint32 SMK_BIG_NODE = 0x80000000;

typedef struct {
	Uint32  _treeSize;
	Uint32* _tree;
	Uint32  _last[3];

	Uint32 _prefixtree[256];
	Uint8 _prefixlength[256];

	/* Used during construction */
	BitStream* _bs;
	Uint32 _markers[3];
	SmallTree* _loBytes;
	SmallTree* _hiBytes;
} BigTree;

static Uint32 BigTree_decodeTree(BigTree*, Uint32 prefix, int length);

static BigTree* BigTree_new(BitStream* bs, int allocSize) {
	BigTree* this = safemalloc(sizeof(BigTree));
	this->_bs = bs;

	if (!BitStream_getBit(bs)) {
		this->_tree = safemalloc(sizeof(Uint32));
		this->_tree[0] = 0;
		this->_last[0] = this->_last[1] = this->_last[2] = 0;
		return this;
	}

	int i;
	for (i = 0; i < 256; i++)
		this->_prefixtree[i] = this->_prefixlength[i] = 0;

	this->_loBytes = SmallTree_new(bs);
	this->_hiBytes = SmallTree_new(bs);

	this->_markers[0] = BitStream_get8(bs) | (BitStream_get8(bs) << 8);
	this->_markers[1] = BitStream_get8(bs) | (BitStream_get8(bs) << 8);
	this->_markers[2] = BitStream_get8(bs) | (BitStream_get8(bs) << 8);

	this->_last[0] = this->_last[1] = this->_last[2] = 0xffffffff;

	this->_treeSize = 0;
	this->_tree = safemalloc(sizeof(Uint32) * (allocSize / 4));

	BigTree_decodeTree(this, 0, 0);

	bool bit = BitStream_getBit(bs);
	assert(!bit);

	for (i = 0; i < 3; i++) {
		if (this->_last[i] == 0xffffffff) {
			this->_last[i] = this->_treeSize;
			this->_tree[this->_treeSize++] = 0;
		}
	}

	safefree(this->_loBytes);
	safefree(this->_hiBytes);

	return this;
}

static void BigTree_destroy(BigTree* this) {
	safefree(this->_tree);
	safefree(this);
}

static void BigTree_reset(BigTree* this) {
	this->_tree[this->_last[0]] = this->_tree[this->_last[1]] = this->_tree[this->_last[2]] = 0;
}

static Uint32 BigTree_decodeTree(BigTree* this, Uint32 prefix, int length) {
	if (!BitStream_getBit(this->_bs)) { // Leaf
		Uint32 lo = SmallTree_getCode(this->_loBytes, this->_bs);
		Uint32 hi = SmallTree_getCode(this->_hiBytes, this->_bs);

		Uint32 v = (hi << 8) | lo;

		this->_tree[this->_treeSize] = v;

		int i;
		if (length <= 8) {
			for (i = 0; i < 256; i += (1 << length)) {
				this->_prefixtree[prefix | i] = this->_treeSize;
				this->_prefixlength[prefix | i] = length;
			}
		}

		for (i = 0; i < 3; i++) {
			if (this->_markers[i] == v) {
				this->_last[i] = this->_treeSize;
				this->_tree[this->_treeSize] = 0;
			}
		}
		this->_treeSize++;

		return 1;
	}

	Uint32 t = this->_treeSize++;

	if (length == 8) {
		this->_prefixtree[prefix] = t;
		this->_prefixlength[prefix] = 8;
	}

	Uint32 r1 = BigTree_decodeTree(this, prefix, length + 1);

	this->_tree[t] = SMK_BIG_NODE | r1;

	Uint32 r2 = BigTree_decodeTree(this, prefix | (1 << length), length + 1);

	return r1 + r2 + 1;
}

static Uint32 BigTree_getCode(BigTree* this, BitStream* bs) {
	Uint8 peek = BitStream_peek8(bs);
	Uint32* p = &this->_tree[this->_prefixtree[peek]];
	BitStream_skip(bs, this->_prefixlength[peek]);

	while (*p & SMK_BIG_NODE) {
		if (BitStream_getBit(bs))
			p += *p & ~SMK_BIG_NODE;
		p++;
	}

	Uint32 v = *p;
	if (v != this->_tree[this->_last[0]]) {
		this->_tree[this->_last[2]] = this->_tree[this->_last[1]];
		this->_tree[this->_last[1]] = this->_tree[this->_last[0]];
		this->_tree[this->_last[0]] = v;
	}

	return v;
}

/*
// class SmackerDecoder
// The main class.
*/

/* possible runs of blocks */
static const int block_runs[64] = {
	 1,    2,    3,    4,    5,    6,    7,    8,
	 9,   10,   11,   12,   13,   14,   15,   16,
	17,   18,   19,   20,   21,   22,   23,   24,
	25,   26,   27,   28,   29,   30,   31,   32,
	33,   34,   35,   36,   37,   38,   39,   40,
	41,   42,   43,   44,   45,   46,   47,   48,
	49,   50,   51,   52,   53,   54,   55,   56,
	57,   58,   59,  128,  256,  512, 1024, 2048 };

typedef enum {
	SMK_BLOCK_MONO = 0,
	SMK_BLOCK_FULL = 1,
	SMK_BLOCK_SKIP = 2,
	SMK_BLOCK_FILL = 3
} BlockTypes;

typedef enum {
	kCompressionNone,
	kCompressionDPCM,
	kCompressionRDFT,
	kCompressionDCT
} AudioCompression;

typedef struct {
	AudioCompression compression;
	bool hasAudio;
	bool is16Bits;
	bool isStereo;
	Uint32 sampleRate;
} AudioInfo;

typedef struct {
	Sint32 _curFrame;

	SDL_RWops* _fileStream;
	SDL_Surface* _surface;

	struct {
		Uint32 signature;
		Uint32 flags;
		Uint32 audioSize[7];
		Uint32 treesSize;
		Uint32 mMapSize;
		Uint32 mClrSize;
		Uint32 fullSize;
		Uint32 typeSize;
		AudioInfo audioInfo[7];
		Uint32 dummy;
	} _header;

	Uint32* _frameSizes;
	/* The FrameTypes section of a Smacker file contains an array of bytes, where
	// the 8 bits of each byte describe the contents of the corresponding frame.
	// The highest 7 bits correspond to audio frames (bit 7 is track 6, bit 6 track 5
	// and so on), so there can be up to 7 different audio tracks. When the lowest bit
	// (bit 0) is set, it denotes a frame that contains a palette record */
	Uint8* _frameTypes;
	Uint8* _frameData;
	int _frameDataStartPos;

	double _frameRate;
	Uint32 _frameCount;

	BigTree* _MMapTree;
	BigTree* _MClrTree;
	BigTree* _FullTree;
	BigTree* _TypeTree;
} SmackerDecoder;

SmackerDecoder* SmackerDecoder_new(SDL_RWops* stream) {
	SmackerDecoder* this = safemalloc(sizeof(SmackerDecoder));

	this->_fileStream = stream;

	/* Read in the Smacker header */
	this->_header.signature = SDL_RWreadUint32(stream);

	if(this->_header.signature != ('S')+('M'<<8)+('K'<<16)+('2'<<24))
		error("Invalid Smacker file");

	Uint32 width      = SDL_RWreadUint32(stream);
	Uint32 height     = SDL_RWreadUint32(stream);

	this->_frameCount = SDL_RWreadUint32(stream);
	Sint32 frameRate;
	SDL_RWread(stream, &frameRate, 4, 1);

	/* framerate contains 2 digits after the comma, so 1497 is actually 14.97 fps */
	if (frameRate > 0)
		this->_frameRate = 1000 / frameRate;
	else if (frameRate < 0)
		this->_frameRate = 100000 / -frameRate;
	else
		this->_frameRate = 1000;

	/* Flags are determined by which bit is set, which can be one of the following:
	// 0 - set to 1 if file contains a ring frame.
	// 1 - set to 1 if file is Y-interlaced
	// 2 - set to 1 if file is Y-doubled
	// If bits 1 or 2 are set, the frame should be scaled to twice its height
	// before it is displayed. */
	this->_header.flags = SDL_RWreadUint32(stream);

	int i;
	for (i = 0; i < 7; i++)
		this->_header.audioSize[i] = SDL_RWreadUint32(stream);

	this->_header.treesSize = SDL_RWreadUint32(stream);
	this->_header.mMapSize  = SDL_RWreadUint32(stream);
	this->_header.mClrSize  = SDL_RWreadUint32(stream);
	this->_header.fullSize  = SDL_RWreadUint32(stream);
	this->_header.typeSize  = SDL_RWreadUint32(stream);

	for (i = 0; i < 7; i++) {
		/* AudioRate - Frequency and format information for each sound track, up to 7 audio tracks.
		// The 32 constituent bits have the following meaning:
		// * bit 31 - indicates Huffman + DPCM compression
		// * bit 30 - indicates that audio data is present for this track
		// * bit 29 - 1 = 16-bit audio; 0 = 8-bit audio
		// * bit 28 - 1 = stereo audio; 0 = mono audio
		// * bit 27 - indicates Bink RDFT compression
		// * bit 26 - indicates Bink DCT compression
		// * bits 25-24 - unused
		// * bits 23-0 - audio sample rate */
		Uint32 audioInfo = SDL_RWreadUint32(stream);
		this->_header.audioInfo[i].hasAudio   = audioInfo & 0x40000000;
		this->_header.audioInfo[i].is16Bits   = audioInfo & 0x20000000;
		this->_header.audioInfo[i].isStereo   = audioInfo & 0x10000000;
		this->_header.audioInfo[i].sampleRate = audioInfo & 0xFFFFFF;

		if (audioInfo & 0x8000000)
			this->_header.audioInfo[i].compression = kCompressionRDFT;
		else if (audioInfo & 0x4000000)
			this->_header.audioInfo[i].compression = kCompressionDCT;
		else if (audioInfo & 0x80000000)
			this->_header.audioInfo[i].compression = kCompressionDPCM;
		else
			this->_header.audioInfo[i].compression = kCompressionNone;

		if (this->_header.audioInfo[i].hasAudio) {
			if (this->_header.audioInfo[i].compression == kCompressionRDFT || this->_header.audioInfo[i].compression == kCompressionDCT)
				error("Unhandled Smacker v2 audio compression");

			printf("%08X", this->_header.audioInfo[i].compression);
		}
	}

	this->_header.dummy = SDL_RWreadUint32(stream);

	this->_frameSizes = safemalloc(sizeof(Uint32) * this->_frameCount);
	for (i = 0; i < this->_frameCount; i++)
		this->_frameSizes[i] = SDL_RWreadUint32(stream);

	this->_frameTypes = safemalloc(this->_frameCount);
	for (i = 0; i < this->_frameCount; i++)
		this->_frameTypes[i] = SDL_RWreadUint8(stream);

	Uint8* huffmanTrees = safemalloc(this->_header.treesSize);
	SDL_RWread(stream, huffmanTrees, this->_header.treesSize, 1);

	BitStream* bs = BitStream_new(huffmanTrees, this->_header.treesSize);

	this->_MMapTree = BigTree_new(bs, this->_header.mMapSize);
	this->_MClrTree = BigTree_new(bs, this->_header.mClrSize);
	this->_FullTree = BigTree_new(bs, this->_header.fullSize);
	this->_TypeTree = BigTree_new(bs, this->_header.typeSize);

	safefree(huffmanTrees);
	safefree(bs);

	this->_frameDataStartPos = SDL_RWtell(stream);
	this->_curFrame = -1;

	this->_surface = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 8, 0, 0, 0, 0);

	return this;
}

static void SmackerDecoder_handleAudioTrack(SmackerDecoder* this, Uint8 track, Uint32 chunkSize, Uint32 unpackedSize);
static void SmackerDecoder_unpackPalette(SmackerDecoder* this);

int SmackerDecoder_nextFrame(SmackerDecoder* this) {
	int i;
	Uint32 chunkSize = 0;
	Uint32 dataSizeUnpacked = 0;

	Uint32 startPos = SDL_RWtell(this->_fileStream);

	/* curFrame starts at -1 so we can do this */
	this->_curFrame++;
	if(this->_curFrame >= this->_frameCount)
		return 0;

	/* Check if we got a frame with palette data, and
	// call back the virtual setPalette function to set
	// the current palette */
	if (this->_frameTypes[this->_curFrame] & 1)
		SmackerDecoder_unpackPalette(this);
	else if(this->_curFrame == 0)
		error("No palette data on first frame");

	/* Load audio tracks */
	for (i = 0; i < 7; i++) {
		if (!(this->_frameTypes[this->_curFrame] & (2 << i)))
			continue;

		chunkSize = SDL_RWreadUint32(this->_fileStream);
		chunkSize -= 4;    /* subtract the first 4 bytes (chunk size) */

		if (this->_header.audioInfo[i].compression == kCompressionNone) {
			dataSizeUnpacked = chunkSize;
		} else {
			dataSizeUnpacked = SDL_RWreadUint32(this->_fileStream);
			chunkSize -= 4;    /* subtract the next 4 bytes (unpacked data size) */
		}

		SmackerDecoder_handleAudioTrack(this, i, chunkSize, dataSizeUnpacked);
	}

	Uint32 frameSize = this->_frameSizes[this->_curFrame] & ~3;
	if (SDL_RWtell(this->_fileStream) - startPos > frameSize) {
		error("Smacker actual frame size exceeds recorded frame size");
	}

	Uint32 frameDataSize = frameSize - (SDL_RWtell(this->_fileStream) - startPos);

	this->_frameData = safemalloc(frameDataSize);
	SDL_RWread(this->_fileStream, this->_frameData, frameDataSize, 1);

	BitStream* bs = BitStream_new(this->_frameData, frameDataSize);

	BigTree_reset(this->_MMapTree);
	BigTree_reset(this->_MClrTree);
	BigTree_reset(this->_FullTree);
	BigTree_reset(this->_TypeTree);

	int bw = this->_surface->w / 4;
	int bh = this->_surface->h / 4;
	int stride = this->_surface->pitch;
	int block = 0, blocks = bw * bh;

	while (block < blocks) {
		int type = BigTree_getCode(this->_TypeTree, bs);
		int run = block_runs[(type >> 2) & 0x3F];
		Uint8* out;

		switch (type & 3) {
		case SMK_BLOCK_MONO:
			while (run-- && block < blocks) {
				Uint32 clr = BigTree_getCode(this->_MClrTree, bs);
				Uint32 map = BigTree_getCode(this->_MMapTree, bs);
				out = (Uint8*)this->_surface->pixels + ((block / bw) * stride + (block % bw)) * 4;
				Uint8 hi = clr >> 8;
				Uint8 lo = clr & 0xff;
				for (i = 0; i < 4; i++) {
					out[0] = (map & 1) ? hi : lo;
					out[1] = (map & 2) ? hi : lo;
					out[2] = (map & 4) ? hi : lo;
					out[3] = (map & 8) ? hi : lo;
					out += stride;
					map >>= 4;
				}
				block++;
			}
			break;
		case SMK_BLOCK_FULL:
			while (run-- && block < blocks) {
				out = (Uint8*)this->_surface->pixels + ((block / bw) * stride + (block % bw)) * 4;
				for (i = 0; i < 4; i++) {
					Uint32 p1 = BigTree_getCode(this->_FullTree, bs);
					Uint32 p2 = BigTree_getCode(this->_FullTree, bs);
					out[2] = p1 & 0xff;
					out[3] = p1 >> 8;
					out[0] = p2 & 0xff;
					out[1] = p2 >> 8;
					out += stride;
				}
				block++;
			}
			break;
		case SMK_BLOCK_SKIP:
			while (run-- && block < blocks)
				block++;
			break;
		case SMK_BLOCK_FILL:
			while (run-- && block < blocks) {
				out = (Uint8*)this->_surface->pixels + ((block / bw) * stride + (block % bw)) * 4;
				Uint32 col = (type >> 8) * 0x01010101;
				for (i = 0; i < 4; i++) {
					out[0] = out[1] = out[2] = out[3] = col;
					out += stride;
				}
				block++;
			}
			break;
		}
	}

	SDL_RWseek(this->_fileStream, startPos + frameSize, SEEK_SET);

	safefree(this->_frameData);
	safefree(bs);

	return 1;
}

void SmackerDecoder_firstFrame(SmackerDecoder* this) {
	/* reset the palette */
	SDL_Color* palette = this->_surface->format->palette->colors;
	memset(palette, 0, 4 * 256);
	SDL_SetColors(this->_surface, palette, 0, 256);

	this->_curFrame = -1;
	SDL_RWseek(this->_fileStream, this->_frameDataStartPos, SEEK_SET);
	SmackerDecoder_nextFrame(this);
}

static void SmackerDecoder_handleAudioTrack(SmackerDecoder* this, Uint8 track, Uint32 chunkSize, Uint32 unpackedSize) {
	if (this->_header.audioInfo[track].hasAudio && chunkSize > 0 && track == 0) {
		/* If it's track 0, play the audio data */
		Uint8* soundBuffer = safemalloc(chunkSize);

		SDL_RWread(this->_fileStream, soundBuffer, chunkSize, 1);

		safefree(soundBuffer);

		/*if (_header.audioInfo[track].compression == kCompressionRDFT || _header.audioInfo[track].compression == kCompressionDCT) {
			// TODO: Compressed audio (Bink RDFT/DCT encoded)
			free(soundBuffer);
			return;
		} else if (_header.audioInfo[track].compression == kCompressionDPCM) {
			// Compressed audio (Huffman DPCM encoded)
			queueCompressedBuffer(soundBuffer, chunkSize, unpackedSize, track);
			free(soundBuffer);
		} else {
			// Uncompressed audio (PCM)
			byte flags = 0;
			if (_header.audioInfo[track].is16Bits)
				flags = flags | Audio::FLAG_16BITS;
			if (_header.audioInfo[track].isStereo)
				flags = flags | Audio::FLAG_STEREO;

			_audioStream->queueBuffer(soundBuffer, chunkSize, DisposeAfterUse::YES, flags);
			// The sound buffer will be deleted by QueuingAudioStream
		}

		if (!_audioStarted) {
			_mixer->playStream(_soundType, &_audioHandle, _audioStream, -1, 255);
			_audioStarted = true;
		}*/
	} else {
		/* Ignore the rest of the audio tracks, if they exist
		// TODO: Are there any Smacker videos with more than one audio stream?
		// If yes, we should play the rest of the audio streams as well */
		if (chunkSize > 0)
			SDL_RWseek(this->_fileStream, chunkSize, SEEK_CUR);
	}
}

/*static void SmackerDecoder::queueCompressedBuffer(byte *buffer, uint32 bufferSize,
		uint32 unpackedSize, int streamNum) {

	BitStream audioBS(buffer, bufferSize);
	bool dataPresent = audioBS.getBit();

	if (!dataPresent)
		return;

	bool isStereo = audioBS.getBit();
	assert(isStereo == _header.audioInfo[streamNum].isStereo);
	bool is16Bits = audioBS.getBit();
	assert(is16Bits == _header.audioInfo[streamNum].is16Bits);

	int numBytes = 1 * (isStereo ? 2 : 1) * (is16Bits ? 2 : 1);

	byte *unpackedBuffer = (byte *)malloc(unpackedSize);
	byte *curPointer = unpackedBuffer;
	uint32 curPos = 0;

	SmallTree *audioTrees[4];
	for (int k = 0; k < numBytes; k++)
		audioTrees[k] = new SmallTree(audioBS);

	// Base values, stored as big endian

	int32 bases[2];

	if (isStereo) {
		if (is16Bits) {
			byte hi = audioBS.getBits8();
			byte lo = audioBS.getBits8();
			bases[1] = (int16) ((hi << 8) | lo);
		} else {
			bases[1] = audioBS.getBits8();
		}
	}

	if (is16Bits) {
		byte hi = audioBS.getBits8();
		byte lo = audioBS.getBits8();
		bases[0] = (int16) ((hi << 8) | lo);
	} else {
		bases[0] = audioBS.getBits8();
	}

	// The bases are the first samples, too
	for (int i = 0; i < (isStereo ? 2 : 1); i++, curPointer += (is16Bits ? 2 : 1), curPos += (is16Bits ? 2 : 1)) {
		if (is16Bits)
			WRITE_BE_UINT16(curPointer, bases[i]);
		else
			*curPointer = (bases[i] & 0xFF) ^ 0x80;
	}

	// Next follow the deltas, which are added to the corresponding base values and
	// are stored as little endian
	// We store the unpacked bytes in big endian format

	while (curPos < unpackedSize) {
		// If the sample is stereo, the data is stored for the left and right channel, respectively
		// (the exact opposite to the base values)
		if (!is16Bits) {
			for (int k = 0; k < (isStereo ? 2 : 1); k++) {
				bases[k] += (int8) ((int16) audioTrees[k]->getCode(audioBS));
				*curPointer++ = CLIP<int>(bases[k], 0, 255) ^ 0x80;
				curPos++;
			}
		} else {
			for (int k = 0; k < (isStereo ? 2 : 1); k++) {
				byte lo = audioTrees[k * 2]->getCode(audioBS);
				byte hi = audioTrees[k * 2 + 1]->getCode(audioBS);
				bases[k] += (int16) (lo | (hi << 8));

				WRITE_BE_UINT16(curPointer, bases[k]);
				curPointer += 2;
				curPos += 2;
			}
		}

	}

	for (int k = 0; k < numBytes; k++)
		delete audioTrees[k];

	byte flags = 0;
	if (_header.audioInfo[0].is16Bits)
		flags = flags | Audio::FLAG_16BITS;
	if (_header.audioInfo[0].isStereo)
		flags = flags | Audio::FLAG_STEREO;
	_audioStream->queueBuffer(unpackedBuffer, unpackedSize, DisposeAfterUse::YES, flags);
	// unpackedBuffer will be deleted by QueuingAudioStream
}*/

static void SmackerDecoder_unpackPalette(SmackerDecoder* this) {
	int startPos = SDL_RWtell(this->_fileStream);
	Uint32 len = 4 * SDL_RWreadUint8(this->_fileStream);

	Uint8* chunk = safemalloc(len);
	SDL_RWread(this->_fileStream, chunk, len, 1);
	Uint8* p = chunk;

	Uint8* newPalette = (Uint8*)this->_surface->format->palette->colors;
	Uint8* pal = newPalette;

	Uint8 oldPalette[4 * 256];
	memcpy(oldPalette, pal, 4 * 256);

	int sz = 0;
	Uint8 b0;
	while (sz < 256) {
		b0 = *p++;
		if (b0 & 0x80) {               /* if top bit is 1 (0x80 = 10000000) */
			sz += (b0 & 0x7f) + 1;     /* get lower 7 bits + 1 (0x7f = 01111111) */
			pal += 4 * ((b0 & 0x7f) + 1);
		}
		else if (b0 & 0x40) {           /* if top 2 bits are 01 (0x40 = 01000000) */
			Uint8 c = (b0 & 0x3f) + 1;  /* get lower 6 bits + 1 (0x3f = 00111111) */
			int s = 4 * *p++;
			sz += c;

			while (c--) {
				*pal++ = oldPalette[s + 0];
				*pal++ = oldPalette[s + 1];
				*pal++ = oldPalette[s + 2];
				pal++;
				s += 4;
			}
		} else {                       /* top 2 bits are 00 */
			sz++;
			/* get the lower 6 bits for each component (0x3f = 00111111) */
			Uint8 b = b0 & 0x3f;
			Uint8 g = *p++ & 0x3f;
			Uint8 r = *p++ & 0x3f;

			assert(g < 0xc0 && b < 0xc0);

			/* upscale to full 8-bit color values by multiplying by 4 */
			*pal++ = b * 4;
			*pal++ = g * 4;
			*pal++ = r * 4;
			pal++;
		}
	}

	SDL_SetColors(this->_surface, (SDL_Color*)newPalette, 0, sz);

	SDL_RWseek(this->_fileStream, startPos + len, SEEK_SET);
	safefree(chunk);
}

#endif

MODULE = Games::Neverhood::SmackerDecoder		PACKAGE = Games::Neverhood::SmackerDecoder		PREFIX = Neverhood_SmackerDecoder_

SmackerDecoder*
Neverhood_SmackerDecoder_new(CLASS, stream)
		const char* CLASS
		SDL_RWops* stream
	CODE:
		RETVAL = SmackerDecoder_new(stream);
	OUTPUT:
		RETVAL

int
Neverhood_SmackerDecoder_next_frame(THIS)
		SmackerDecoder* THIS
	CODE:
		RETVAL = SmackerDecoder_nextFrame(THIS);
	OUTPUT:
		RETVAL

void
Neverhood_SmackerDecoder_first_frame(THIS)
		SmackerDecoder* THIS
	CODE:
		SmackerDecoder_firstFrame(THIS);

SDL_Surface*
Neverhood_SmackerDecoder_get_surface(THIS)
		SmackerDecoder* THIS
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = THIS->_surface;
	OUTPUT:
		RETVAL

Sint32
Neverhood_SmackerDecoder_get_cur_frame(THIS)
		SmackerDecoder* THIS
	CODE:
		RETVAL = THIS->_curFrame;
	OUTPUT:
		RETVAL

Uint32
Neverhood_SmackerDecoder_get_frame_count(THIS)
		SmackerDecoder* THIS
	CODE:
		RETVAL = THIS->_frameCount;
	OUTPUT:
		RETVAL

double
Neverhood_SmackerDecoder_get_frame_rate(THIS)
		SmackerDecoder* THIS
	CODE:
		RETVAL = THIS->_frameRate;
	OUTPUT:
		RETVAL

void
Neverhood_SmackerDecoder_DESTROY(THIS)
		SmackerDecoder* THIS
	CODE:
		SDL_FreeSurface(THIS->_surface);
		SDL_RWclose(THIS->_fileStream);
		safefree(THIS->_frameSizes);
		safefree(THIS->_frameTypes);
		BigTree_destroy(THIS->_MMapTree);
		BigTree_destroy(THIS->_MClrTree);
		BigTree_destroy(THIS->_FullTree);
		BigTree_destroy(THIS->_TypeTree);
		safefree(THIS);
