/*
// Smacker resource - decodes smacker movie files and plays them
// Based heavily on the ScummVM v1.3.1 Smacker decoder (video/smkdecoder).
// https://github.com/scummvm/scummvm/tree/42ab839dd6c8a1570b232101eb97f4e54de57935/video
// However it removes any code that the Neverhood smacker files don't need
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#undef NDEBUG
#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <smacker.h>
#include <helper.h>
#include <resource.h>
#include <memory.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

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
	Uint8 hasAudio;
	Uint8 is16Bits;
	Uint8 isStereo;
	Uint32 sampleRate;
} AudioInfo;

typedef struct BufferLink {
	Uint8* buf;
	int len;
	struct BufferLink* nextLink;
} BufferLink;

typedef struct {
	Uint8* curPos;
	int remainingLen;
	BufferLink* curLink;
	BufferLink* earliestLink;
	BufferLink** latestLink;
} SmackerAudio;

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

	SmackerAudio* _audio;
	SDL_AudioCVT* _cvt;
} SmackerResource;

SmackerResource* SmackerResource_new(SDL_RWops* stream) {
	SmackerResource* this = safemalloc(sizeof(SmackerResource));

	this->_fileStream = stream;

	/* Read in the Smacker header */
	this->_header.signature = SDL_ReadLE32(stream);

	if (this->_header.signature != ('S'<<0)+('M'<<8)+('K'<<16)+('2'<<24))
		error("Invalid Smacker file");

	Uint32 width  = SDL_ReadLE32(stream);
	Uint32 height = SDL_ReadLE32(stream);

	this->_frameCount = SDL_ReadLE32(stream);
	Sint32 frameRate  = SDL_ReadLE32(stream);

	/* framerate contains 2 digits after the comma, so 1497 is actually 14.97 fps */
	this->_frameRate =
			frameRate > 0 ? 1000.0   /  frameRate :
			frameRate < 0 ? 100000.0 / -frameRate :
			                1000.0;

	/* Flags are determined by which bit is set, which can be one of the following:
	// 0 - set to 1 if file contains a ring frame.
	// 1 - set to 1 if file is Y-interlaced
	// 2 - set to 1 if file is Y-doubled
	// If bits 1 or 2 are set, the frame should be scaled to twice its height
	// before it is displayed. */
	this->_header.flags = SDL_ReadLE32(stream);

	int i;
	for (i = 0; i < 7; i++)
		this->_header.audioSize[i] = SDL_ReadLE32(stream);

	this->_header.treesSize = SDL_ReadLE32(stream);
	this->_header.mMapSize  = SDL_ReadLE32(stream);
	this->_header.mClrSize  = SDL_ReadLE32(stream);
	this->_header.fullSize  = SDL_ReadLE32(stream);
	this->_header.typeSize  = SDL_ReadLE32(stream);

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
		Uint32 audioInfo = SDL_ReadLE32(stream);
		this->_header.audioInfo[i].hasAudio   = (audioInfo & 0x40000000) >> 30;
		this->_header.audioInfo[i].is16Bits   = (audioInfo & 0x20000000) >> 29;
		this->_header.audioInfo[i].isStereo   = (audioInfo & 0x10000000) >> 28;
		this->_header.audioInfo[i].sampleRate = audioInfo & 0xFFFFFF;

		if (audioInfo & 0x8000000)
			this->_header.audioInfo[i].compression = kCompressionRDFT;
		else if (audioInfo & 0x4000000)
			this->_header.audioInfo[i].compression = kCompressionDCT;
		else if (audioInfo & 0x80000000)
			this->_header.audioInfo[i].compression = kCompressionDPCM;
		else
			this->_header.audioInfo[i].compression = kCompressionNone;

		if (this->_header.audioInfo[i].hasAudio && this->_header.audioInfo[i].compression != kCompressionDPCM)
			error("Unhandled Smacker audio: %d", (int)this->_header.audioInfo[i].compression);
	}

	this->_header.dummy = SDL_ReadLE32(stream);

	this->_frameSizes = safemalloc(sizeof(Uint32) * this->_frameCount);
	for (i = 0; i < this->_frameCount; i++)
		this->_frameSizes[i] = SDL_ReadLE32(stream);

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

	this->_audio = NULL;
	this->_cvt   = NULL;

	return this;
}

void SmackerResource_destroyAudio(SmackerResource* this) {
	if(this->_audio) {
		if(Mix_GetMusicHookData() == this->_audio)
			Mix_HookMusic(NULL, NULL);

		while (this->_audio->earliestLink) {
			BufferLink* oldLink = this->_audio->earliestLink;
			this->_audio->earliestLink = oldLink->nextLink;
			safefree(oldLink->buf);
			safefree(oldLink);
		}
		safefree(this->_audio);
		safefree(this->_cvt);
	}
}

void SmackerResource_destroy(SmackerResource* this) {
	safefree(this->_frameSizes);
	safefree(this->_frameTypes);
	BigTree_destroy(this->_MMapTree);
	BigTree_destroy(this->_MClrTree);
	BigTree_destroy(this->_FullTree);
	BigTree_destroy(this->_TypeTree);
	SmackerResource_destroyAudio(this);
	safefree(this);
}

static void SmackerResource_handleAudioTrack(SmackerResource* this, Uint8 track, Uint32 chunkSize, Uint32 unpackedSize);
static void SmackerResource_unpackPalette(SmackerResource* this);
static void SmackerResource_player(void* udata, Uint8* buf, int len);

int SmackerResource_nextFrame(SmackerResource* this) {
	int i;
	Uint32 chunkSize = 0;
	Uint32 dataSizeUnpacked = 0;

	Uint32 startPos = SDL_RWtell(this->_fileStream);

	/* curFrame starts at -1 so we can do this */
	this->_curFrame++;
	if (this->_curFrame >= this->_frameCount) {
		Mix_HookMusic(NULL, NULL);
		return 0;
	}

	/* Check if we got a frame with palette data, and
	// call back the virtual setPalette function to set
	// the current palette */
	if (this->_frameTypes[this->_curFrame] & 1)
		SmackerResource_unpackPalette(this);
	else if (this->_curFrame == 0)
		error("No palette data on first frame");

	/* Load audio tracks */
	for (i = 0; i < 7; i++) {
		if (!(this->_frameTypes[this->_curFrame] & (2 << i)))
			continue;

		chunkSize = SDL_ReadLE32(this->_fileStream);
		chunkSize -= 4;    /* subtract the first 4 bytes (chunk size) */

		if (this->_header.audioInfo[i].compression == kCompressionNone) {
			dataSizeUnpacked = chunkSize;
		} else {
			dataSizeUnpacked = SDL_ReadLE32(this->_fileStream);
			chunkSize -= 4;    /* subtract the next 4 bytes (unpacked data size) */
		}

		SmackerResource_handleAudioTrack(this, i, chunkSize, dataSizeUnpacked);
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
		int run = ((type >> 2) & 0x3F) + 1;
		if (run >= 60) run = 128 << (run - 60);
		int extraVal = type >> 8;
		type &= 3;

		while (run-- && block < blocks) {
			Uint8* out = (Uint8*)this->_surface->pixels + ((block / bw) * stride + (block % bw)) * 4;
			block++;

			switch (type) {
				case SMK_BLOCK_MONO: {
					Uint32 clr = BigTree_getCode(this->_MClrTree, bs);
					Uint32 map = BigTree_getCode(this->_MMapTree, bs);
					Uint8 hi = clr >> 8;
					Uint8 lo = clr & 0xff;
					for (i = 0; i < 4; i++) {
						out[0] = map & 1 ? hi : lo;
						out[1] = map & 2 ? hi : lo;
						out[2] = map & 4 ? hi : lo;
						out[3] = map & 8 ? hi : lo;
						out += stride;
						map >>= 4;
					}
					break;
				}
				case SMK_BLOCK_FULL: {
					for (i = 0; i < 4; i++) {
						Uint32 p1 = BigTree_getCode(this->_FullTree, bs);
						Uint32 p2 = BigTree_getCode(this->_FullTree, bs);
						out[2] = p1 & 0xff;
						out[3] = p1 >> 8;
						out[0] = p2 & 0xff;
						out[1] = p2 >> 8;
						out += stride;
					}
					break;
				}
				case SMK_BLOCK_SKIP:
					break;
				case SMK_BLOCK_FILL: {
					Uint32 col = extraVal * 0x01010101;
					for (i = 0; i < 4; i++) {
						out[0] = out[1] = out[2] = out[3] = col;
						out += stride;
					}
					break;
				}
			}
		}
	}

	SDL_RWseek(this->_fileStream, startPos + frameSize, SEEK_SET);

	safefree(this->_frameData);
	safefree(bs);

	/* cleanup consumed buffer links */
	if(this->_audio) {
		while (this->_audio->earliestLink && this->_audio->earliestLink != this->_audio->curLink) {
			BufferLink* oldLink = this->_audio->earliestLink;
			this->_audio->earliestLink = oldLink->nextLink;
			safefree(oldLink->buf);
			safefree(oldLink);
		}
		this->_audio->earliestLink = this->_audio->curLink;
	}

	return 1;
}

void SmackerResource_firstFrame(SmackerResource* this) {
	this->_curFrame = -1;

	Mix_HookMusic(NULL, NULL);

	/* reset the palette */
	SDL_Color* palette = this->_surface->format->palette->colors;
	memset(palette, 0, 4 * 256);
	SDL_SetColors(this->_surface, palette, 0, 256);

	SDL_RWseek(this->_fileStream, this->_frameDataStartPos, SEEK_SET);
	SmackerResource_nextFrame(this);
}

static void SmackerResource_unpackCompressedAudio
(SmackerResource* this, Uint8* buffer, Uint32 bufferSize, Uint8* unpackedBuffer, Uint32 unpackedSize);

static void SmackerResource_handleAudioTrack(SmackerResource* this, Uint8 track, Uint32 chunkSize, Uint32 unpackedSize) {
	if (track == 0 && this->_header.audioInfo[0].hasAudio && chunkSize > 0) {
		/* If it's track 0, play the audio data */
		Uint8* soundBuffer = safemalloc(chunkSize);
		SDL_RWread(this->_fileStream, soundBuffer, chunkSize, 1);

		if(!this->_cvt) {
			this->_cvt = safemalloc(sizeof(SDL_AudioCVT));
			Uint16 format = (this->_header.audioInfo[0].is16Bits ? AUDIO_S16LSB : AUDIO_S8);
			SDL_BuildSpecAudioCVT(this->_cvt, format, 1, this->_header.audioInfo[0].sampleRate);
		}

		Uint8* unpackedBuffer = (Uint8*)safemalloc(unpackedSize * this->_cvt->len_mult);

		if (this->_header.audioInfo[0].compression == kCompressionDPCM) {
			SmackerResource_unpackCompressedAudio(this, soundBuffer, chunkSize, unpackedBuffer, unpackedSize);
			safefree(soundBuffer);
		}

		this->_cvt->buf = unpackedBuffer;
		this->_cvt->len = unpackedSize;
		SDL_ConvertAudio(this->_cvt);

		BufferLink* link = safemalloc(sizeof(BufferLink));
		link->buf = unpackedBuffer;
		link->len = unpackedSize * this->_cvt->len_ratio;
		link->nextLink = NULL;

		if (!this->_audio) {
			this->_audio = safemalloc(sizeof(SmackerAudio));
			this->_audio->curLink = NULL;
			this->_audio->earliestLink = link;
		}

		SDL_LockAudio();

		if (!this->_audio->curLink) {
			this->_audio->curLink      = link;
			this->_audio->curPos       = link->buf;
			this->_audio->remainingLen = link->len;
		}
		else {
			*this->_audio->latestLink = link;
		}
		this->_audio->latestLink = &link->nextLink;

		SDL_UnlockAudio();

		Mix_HookMusic(SmackerResource_player, (void*)this->_audio);
	}
	else if (chunkSize > 0) {
		/* Ignore the rest of the audio tracks, if they exist */
		SDL_RWseek(this->_fileStream, chunkSize, SEEK_CUR);
	}
}

static void SmackerResource_unpackCompressedAudio
(SmackerResource* this, Uint8* buffer, Uint32 bufferSize, Uint8* unpackedBuffer, Uint32 unpackedSize)
{
	BitStream* audioBS = BitStream_new(buffer, bufferSize);

	if (!BitStream_getBit(audioBS)) {
		safefree(audioBS);
		return;
	}

	Uint8 isStereo = BitStream_getBit(audioBS);
	assert(isStereo == this->_header.audioInfo[0].isStereo);
	Uint8 is16Bits = BitStream_getBit(audioBS);
	assert(is16Bits == this->_header.audioInfo[0].is16Bits);
	assert(!isStereo);

	Uint8* curPointer = unpackedBuffer;
	int curPos = 0;

	SmallTree* audioTrees[2];
	int k;
	for (k = 0; k < (is16Bits ? 2 : 1); k++)
		audioTrees[k] = SmallTree_new(audioBS);

	/* Base value, stored as big endian */
	/* The base is the first sample, too */
	Sint16 base;
	if (is16Bits) {
		Uint8 hi = BitStream_get8(audioBS);
		Uint8 lo = BitStream_get8(audioBS);
		base = (Sint16)((hi << 8) | lo);

		*(Uint16*)curPointer = base;
		curPointer += 2;
		curPos += 2;
	} else {
		base = (Sint16)BitStream_get8(audioBS);
		*curPointer++ = (base & 0xFF) ^ 0x80;
		curPos++;
	}

	/* Next follow the deltas, which are added to the base value and
	// are stored as little endian
	// We store the unpacked bytes in little endian format */

	while (curPos < unpackedSize) {
		if (is16Bits) {
			Uint8 lo = SmallTree_getCode(audioTrees[0], audioBS);
			Uint8 hi = SmallTree_getCode(audioTrees[1], audioBS);
			base += (Sint16)(lo | (hi << 8));

			*(Uint16*)curPointer = base;
			curPointer += 2;
			curPos += 2;
		} else {
			base += (Sint8)SmallTree_getCode(audioTrees[0], audioBS);
			*curPointer++ = (base < 0 ? 0 : base > 255 ? 255 : base) ^ 0x80;
			curPos++;
		}
	}

	for (k = 0; k < (is16Bits ? 2 : 1); k++)
		safefree(audioTrees[k]);

	safefree(audioBS);
}

static void SmackerResource_player(void* udata, Uint8* buf, int len) {
	if (!udata || Mix_PausedMusic()) return;
	SmackerAudio* this = (SmackerAudio*)udata;
	if (!this->curLink) return;

	Uint8* outputBuf = buf;

	if (this->remainingLen <= len) {
		memcpy(outputBuf, this->curPos, this->remainingLen);

		/* switch to the next buffer in the linked list */
		this->curLink = this->curLink->nextLink;

		if (this->curLink) {
			outputBuf += this->remainingLen;
			len -= this->remainingLen;
			this->curPos       = this->curLink->buf;
			this->remainingLen = this->curLink->len;
		}
	}
	if (this->curLink) {
		memcpy(outputBuf, this->curPos, len);
		this->curPos += len;
		this->remainingLen -= len;
	}
}

static void SmackerResource_unpackPalette(SmackerResource* this) {
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

MODULE = Games::Neverhood::SmackerResource		PACKAGE = Games::Neverhood::SmackerResource		PREFIX = Neverhood_SmackerResource_

SmackerResource*
Neverhood_SmackerResource_new(CLASS, stream)
		const char* CLASS
		SDL_RWops* stream
	CODE:
		RETVAL = SmackerResource_new(stream);
	OUTPUT:
		RETVAL

int
Neverhood_SmackerResource_next_frame(THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = SmackerResource_nextFrame(THIS);
	OUTPUT:
		RETVAL

void
Neverhood_SmackerResource_first_frame(THIS)
		SmackerResource* THIS
	CODE:
		SmackerResource_firstFrame(THIS);

SDL_Surface*
Neverhood_SmackerResource_get_surface(THIS)
		SmackerResource* THIS
	INIT:
		const char* CLASS = "SDL::Surface";
	CODE:
		RETVAL = THIS->_surface;
	OUTPUT:
		RETVAL

Sint32
Neverhood_SmackerResource_get_cur_frame(THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = THIS->_curFrame;
	OUTPUT:
		RETVAL

Uint32
Neverhood_SmackerResource_get_frame_count(THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = THIS->_frameCount;
	OUTPUT:
		RETVAL

double
Neverhood_SmackerResource_get_frame_rate(THIS)
		SmackerResource* THIS
	CODE:
		RETVAL = THIS->_frameRate;
	OUTPUT:
		RETVAL

void
Neverhood_SmackerResource_DESTROY(THIS)
		SmackerResource* THIS
	CODE:
		SmackerResource_destroy(THIS);
