/*
// SmackerResource - decodes smacker movie files and plays them
// Based heavily on the ScummVM v1.3.1 Smacker decoder (video/smkdecoder).
// https://github.com/scummvm/scummvm/tree/42ab839dd6c8a1570b232101eb97f4e54de57935/video
// However it removes any code that the Neverhood smacker files don't need
// Copyright (C) 2012 Blaise Roth

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef __SMACKER_RESOURCE__
#define __SMACKER_RESOURCE__

#undef NDEBUG
#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <smacker.h>
#include <ResourceEntry.h>
#include <memory.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

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
	int size;
	struct BufferLink* nextLink;
} BufferLink;

typedef struct {
	Uint8* curPos;
	int remainingSize;
	BufferLink* curLink;
	BufferLink* earliestLink;
	BufferLink** latestLink;
} SmackerAudio;

typedef struct {
	Sint32 curFrame;

	SDL_RWops* fileStream;
	SDL_Surface* surface;

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
	} header;

	Uint32* frameSizes;
	/* The FrameTypes section of a Smacker file contains an array of bytes, where
	// the 8 bits of each byte describe the contents of the corresponding frame.
	// The highest 7 bits correspond to audio frames (bit 7 is track 6, bit 6 track 5
	// and so on), so there can be up to 7 different audio tracks. When the lowest bit
	// (bit 0) is set, it denotes a frame that contains a palette record */
	Uint8* frameTypes;
	Uint8* frameData;
	int frameDataStartPos;

	double frameRate;
	Uint32 frameCount;

	BigTree* MMapTree;
	BigTree* MClrTree;
	BigTree* FullTree;
	BigTree* TypeTree;

	SmackerAudio* audio;
	SDL_AudioCVT* cvt;
} SmackerResource;

SmackerResource* SmackerResource_new (ResourceEntry* entry);
int SmackerResource_nextFrame (SmackerResource* this);
void SmackerResource_stop (SmackerResource* this);
void SmackerResource_player (SmackerAudio* this, Uint8* buf, int size);
void SmackerResource_destroy (SmackerResource* this);

typedef enum {
	SMK_BLOCK_MONO = 0,
	SMK_BLOCK_FULL = 1,
	SMK_BLOCK_SKIP = 2,
	SMK_BLOCK_FILL = 3
} BlockTypes;

SmackerResource* SmackerResource_new (ResourceEntry* entry)
{
	SmackerResource* this = safemalloc(sizeof(SmackerResource));

	if (entry->type != 0xA)
		error("Wrong type for resource: %08X, type: %X", entry->key, entry->type);

	SDL_RWops* stream = ResourceEntry_getStream(entry);
	this->fileStream = stream;

	/* Read in the Smacker header */
	this->header.signature = SDL_ReadLE32(stream);

	if (this->header.signature != ('S'<<0)+('M'<<8)+('K'<<16)+('2'<<24))
		error("Invalid Smacker file");

	Uint32 width  = SDL_ReadLE32(stream);
	Uint32 height = SDL_ReadLE32(stream);

	this->frameCount = SDL_ReadLE32(stream);
	Sint32 frame_rate  = SDL_ReadLE32(stream);

	/* framerate contains 2 digits after the comma, so 1497 is actually 14.97 fps */
	this->frameRate =
			frame_rate > 0 ? 1000.0   /  frame_rate :
			frame_rate < 0 ? 100000.0 / -frame_rate :
			                1000.0;

	/* Flags are determined by which bit is set, which can be one of the following:
	// 0 - set to 1 if file contains a ring frame.
	// 1 - set to 1 if file is Y-interlaced
	// 2 - set to 1 if file is Y-doubled
	// If bits 1 or 2 are set, the frame should be scaled to twice its height
	// before it is displayed. */
	this->header.flags = SDL_ReadLE32(stream);

	int i;
	for (i = 0; i < 7; i++)
		this->header.audioSize[i] = SDL_ReadLE32(stream);

	this->header.treesSize = SDL_ReadLE32(stream);
	this->header.mMapSize  = SDL_ReadLE32(stream);
	this->header.mClrSize  = SDL_ReadLE32(stream);
	this->header.fullSize  = SDL_ReadLE32(stream);
	this->header.typeSize  = SDL_ReadLE32(stream);

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
		Uint32 audio_info = SDL_ReadLE32(stream);
		this->header.audioInfo[i].hasAudio   = (audio_info & 0x40000000) >> 30;
		this->header.audioInfo[i].is16Bits   = (audio_info & 0x20000000) >> 29;
		this->header.audioInfo[i].isStereo   = (audio_info & 0x10000000) >> 28;
		this->header.audioInfo[i].sampleRate = audio_info & 0xFFFFFF;

		if (audio_info & 0x8000000)
			this->header.audioInfo[i].compression = kCompressionRDFT;
		else if (audio_info & 0x4000000)
			this->header.audioInfo[i].compression = kCompressionDCT;
		else if (audio_info & 0x80000000)
			this->header.audioInfo[i].compression = kCompressionDPCM;
		else
			this->header.audioInfo[i].compression = kCompressionNone;

		if (this->header.audioInfo[i].hasAudio && this->header.audioInfo[i].compression != kCompressionDPCM)
			error("Unhandled Smacker audio: %d", (int)this->header.audioInfo[i].compression);
	}

	this->header.dummy = SDL_ReadLE32(stream);

	this->frameSizes = safemalloc(sizeof(Uint32) * this->frameCount);
	for (i = 0; i < this->frameCount; i++)
		this->frameSizes[i] = SDL_ReadLE32(stream);

	this->frameTypes = safemalloc(this->frameCount);
	for (i = 0; i < this->frameCount; i++)
		this->frameTypes[i] = SDL_RWreadUint8(stream);

	Uint8* huffman_trees = safemalloc(this->header.treesSize);
	SDL_RWread(stream, huffman_trees, this->header.treesSize, 1);

	BitStream* bs = BitStream_new(huffman_trees, this->header.treesSize);

	this->MMapTree = BigTree_new(bs, this->header.mMapSize);
	this->MClrTree = BigTree_new(bs, this->header.mClrSize);
	this->FullTree = BigTree_new(bs, this->header.fullSize);
	this->TypeTree = BigTree_new(bs, this->header.typeSize);

	safefree(huffman_trees);
	safefree(bs);

	this->frameDataStartPos = SDL_RWtell(stream);
	this->curFrame = -1;

	this->surface = SDL_CreateRGBSurface(SDL_SWSURFACE, width, height, 8, 0, 0, 0, 0);

	this->audio = NULL;
	this->cvt   = NULL;

	return this;
}

static void SmackerResource_handleAudioTrack (SmackerResource* this, Uint8 track, Uint32 chunk_size, Uint32 unpacked_size);
static void SmackerResource_unpackPalette (SmackerResource* this);
static void SmackerResource_destroyAudio (SmackerResource* this);

int SmackerResource_nextFrame (SmackerResource* this)
{
	int i;
	Uint32 chunk_size = 0;
	Uint32 data_size_unpacked = 0;

	Uint32 start_pos = SDL_RWtell(this->fileStream);

	/* curFrame starts at -1 so we can do this */
	this->curFrame++;
	if (this->curFrame >= this->frameCount) {
		SmackerResource_destroyAudio(this);
		return 0;
	}

	/* Check if we got a frame with palette data, and
	// call back the virtual setPalette function to set
	// the current palette */
	if (this->frameTypes[this->curFrame] & 1)
		SmackerResource_unpackPalette(this);
	else if (this->curFrame == 0)
		error("No palette data on first frame");

	/* Load audio tracks */
	for (i = 0; i < 7; i++) {
		if (!(this->frameTypes[this->curFrame] & (2 << i)))
			continue;

		chunk_size = SDL_ReadLE32(this->fileStream);
		chunk_size -= 4;    /* subtract the first 4 bytes (chunk size) */

		if (this->header.audioInfo[i].compression == kCompressionNone) {
			data_size_unpacked = chunk_size;
		} else {
			data_size_unpacked = SDL_ReadLE32(this->fileStream);
			chunk_size -= 4;    /* subtract the next 4 bytes (unpacked data size) */
		}

		SmackerResource_handleAudioTrack(this, i, chunk_size, data_size_unpacked);
	}

	Uint32 frame_size = this->frameSizes[this->curFrame] & ~3;
	if (SDL_RWtell(this->fileStream) - start_pos > frame_size) {
		error("Smacker actual frame size exceeds recorded frame size");
	}

	Uint32 frame_data_size = frame_size - (SDL_RWtell(this->fileStream) - start_pos);

	this->frameData = safemalloc(frame_data_size);
	SDL_RWread(this->fileStream, this->frameData, frame_data_size, 1);

	BitStream* bs = BitStream_new(this->frameData, frame_data_size);

	BigTree_reset(this->MMapTree);
	BigTree_reset(this->MClrTree);
	BigTree_reset(this->FullTree);
	BigTree_reset(this->TypeTree);

	int bw = this->surface->w / 4;
	int bh = this->surface->h / 4;
	int stride = this->surface->pitch;
	int block = 0, blocks = bw * bh;

	while (block < blocks) {
		int type = BigTree_getCode(this->TypeTree, bs);
		int run = ((type >> 2) & 0x3F) + 1;
		if (run >= 60) run = 128 << (run - 60);
		int extra_val = type >> 8;
		type &= 3;

		while (run-- && block < blocks) {
			Uint8* out = (Uint8*)this->surface->pixels + ((block / bw) * stride + (block % bw)) * 4;
			block++;

			switch (type) {
				case SMK_BLOCK_MONO: {
					Uint32 clr = BigTree_getCode(this->MClrTree, bs);
					Uint32 map = BigTree_getCode(this->MMapTree, bs);
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
						Uint32 p1 = BigTree_getCode(this->FullTree, bs);
						Uint32 p2 = BigTree_getCode(this->FullTree, bs);
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
					Uint32 col = extra_val * 0x01010101;
					for (i = 0; i < 4; i++) {
						out[0] = out[1] = out[2] = out[3] = col;
						out += stride;
					}
					break;
				}
			}
		}
	}

	SDL_RWseek(this->fileStream, start_pos + frame_size, SEEK_SET);

	safefree(this->frameData);
	safefree(bs);

	/* cleanup consumed buffer links */
	SDL_LockAudio();
	if (this->audio) {
		while (this->audio->earliestLink && this->audio->earliestLink != this->audio->curLink) {
			BufferLink* old_link = this->audio->earliestLink;
			this->audio->earliestLink = old_link->nextLink;
			safefree(old_link->buf);
			safefree(old_link);
		}
		this->audio->earliestLink = this->audio->curLink;
	}
	SDL_UnlockAudio();

	return 1;
}

void SmackerResource_stop (SmackerResource* this)
{
	this->curFrame = -1;

	SmackerResource_destroyAudio(this);

	/* reset the palette */
	SDL_Color* palette = this->surface->format->palette->colors;
	memset(palette, 0, 4 * 256);
	SDL_SetColors(this->surface, palette, 0, 256);

	SDL_RWseek(this->fileStream, this->frameDataStartPos, SEEK_SET);
}

static void SmackerResource_unpackCompressedAudio
(SmackerResource* this, Uint8* buffer, Uint32 buffer_size, Uint8* unpacked_buffer, Uint32 unpacked_size);

static void SmackerResource_handleAudioTrack (SmackerResource* this, Uint8 track, Uint32 chunk_size, Uint32 unpacked_size)
{
	if (track == 0 && this->header.audioInfo[0].hasAudio && chunk_size > 0) {
		/* If it's track 0, play the audio data */
		Uint8* sound_buffer = safemalloc(chunk_size);
		SDL_RWread(this->fileStream, sound_buffer, chunk_size, 1);

		if (!this->cvt) {
			this->cvt = safemalloc(sizeof(SDL_AudioCVT));
			Uint16 format = this->header.audioInfo[0].is16Bits ? AUDIO_S16LSB : AUDIO_S8;
			int samplesPerSecond = this->header.audioInfo[0].sampleRate;
			SDL_BuildSpecAudioCVT(this->cvt, format, 1, samplesPerSecond);
			
			//int bytesPerSample = this->header.audioInfo[0].is16Bits ? 2 : 1;
			//this->bytesPerSecond = bytesPerSample * samplesPerSecond;
		}

		Uint8* unpacked_buffer = (Uint8*)safemalloc(unpacked_size * this->cvt->len_mult);

		if (this->header.audioInfo[0].compression == kCompressionDPCM) {
			SmackerResource_unpackCompressedAudio(this, sound_buffer, chunk_size, unpacked_buffer, unpacked_size);
			safefree(sound_buffer);
		}

		this->cvt->buf = unpacked_buffer;
		this->cvt->len = unpacked_size;
		SDL_ConvertAudio(this->cvt);

		BufferLink* link = safemalloc(sizeof(BufferLink));
		link->buf = unpacked_buffer;
		link->size = unpacked_size * this->cvt->len_ratio;
		link->nextLink = NULL;

		if (!this->audio) {
			this->audio = safemalloc(sizeof(SmackerAudio));
			this->audio->curLink = NULL;
			this->audio->earliestLink = link;
		}

		SDL_LockAudio();

		if (!this->audio->curLink) {
			this->audio->curLink       = link;
			this->audio->curPos        = link->buf;
			this->audio->remainingSize = link->size;
		}
		else {
			*this->audio->latestLink = link;
		}
		this->audio->latestLink = &link->nextLink;

		*(SmackerAudio**)Mix_GetMusicHookData() = this->audio;

		SDL_UnlockAudio();
	}
	else if (chunk_size > 0) {
		/* Ignore the rest of the audio tracks, if they exist */
		SDL_RWseek(this->fileStream, chunk_size, SEEK_CUR);
	}
}

static void SmackerResource_unpackCompressedAudio
(SmackerResource* this, Uint8* buffer, Uint32 buffer_size, Uint8* unpacked_buffer, Uint32 unpacked_size)
{
	BitStream* audio_bs = BitStream_new(buffer, buffer_size);

	if (!BitStream_getBit(audio_bs)) {
		safefree(audio_bs);
		return;
	}

	bool is_stereo = BitStream_getBit(audio_bs);
	assert(is_stereo == this->header.audioInfo[0].isStereo);
	bool is_16_bits = BitStream_getBit(audio_bs);
	assert(is_16_bits == this->header.audioInfo[0].is16Bits);
	assert(!is_stereo);

	Uint8* cur_pointer = unpacked_buffer;
	int cur_pos = 0;

	SmallTree* audio_trees[2];
	int k;
	for (k = 0; k < (is_16_bits ? 2 : 1); k++)
		audio_trees[k] = SmallTree_new(audio_bs);

	/* Base value, stored as big endian */
	/* The base is the first sample, too */
	Sint16 base;
	if (is_16_bits) {
		Uint8 hi = BitStream_get8(audio_bs);
		Uint8 lo = BitStream_get8(audio_bs);
		base = (Sint16)((hi << 8) | lo);

		*(Uint16*)cur_pointer = base;
		cur_pointer += 2;
		cur_pos += 2;
	} else {
		base = (Sint16)BitStream_get8(audio_bs);
		*cur_pointer++ = (base & 0xFF) ^ 0x80;
		cur_pos++;
	}

	/* Next follow the deltas, which are added to the base value and
	// are stored as little endian
	// We store the unpacked bytes in little endian format */

	while (cur_pos < unpacked_size) {
		if (is_16_bits) {
			Uint8 lo = SmallTree_getCode(audio_trees[0], audio_bs);
			Uint8 hi = SmallTree_getCode(audio_trees[1], audio_bs);
			base += (Sint16)(lo | (hi << 8));

			*(Uint16*)cur_pointer = base;
			cur_pointer += 2;
			cur_pos += 2;
		} else {
			base += (Sint8)SmallTree_getCode(audio_trees[0], audio_bs);
			*cur_pointer++ = (base < 0 ? 0 : base > 255 ? 255 : base) ^ 0x80;
			cur_pos++;
		}
	}

	for (k = 0; k < (is_16_bits ? 2 : 1); k++)
		safefree(audio_trees[k]);

	safefree(audio_bs);
}

void SmackerResource_player (SmackerAudio* this, Uint8* buf, int size)
{
	if (!this->curLink) {
		memset(buf, 0, size); /* empty out the rest of the buffer */
		return;
	}

	int size_taken = this->remainingSize < size ? this->remainingSize : size;
	memcpy(buf, this->curPos, size_taken);
	buf += size_taken;
	size -= size_taken;
	this->curPos += size_taken;
	this->remainingSize -= size_taken;

	if (this->remainingSize <= 0) {
		this->curLink = this->curLink->nextLink;
		if (this->curLink) {
			this->curPos = this->curLink->buf;
			this->remainingSize = this->curLink->size;
		}
	}

	if (size > 0)
		SmackerResource_player(this, buf, size);
}

static void SmackerResource_unpackPalette (SmackerResource* this)
{
	int start_pos = SDL_RWtell(this->fileStream);
	Uint32 size = 4 * SDL_RWreadUint8(this->fileStream);

	Uint8* chunk = safemalloc(size);
	SDL_RWread(this->fileStream, chunk, size, 1);
	Uint8* p = chunk;

	Uint8* new_palette = (Uint8*)this->surface->format->palette->colors;
	Uint8* pal = new_palette;

	Uint8 old_palette[4 * 256];
	memcpy(old_palette, pal, 4 * 256);

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
				*pal++ = old_palette[s + 0];
				*pal++ = old_palette[s + 1];
				*pal++ = old_palette[s + 2];
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

	SDL_SetColors(this->surface, (SDL_Color*)new_palette, 0, sz);

	SDL_RWseek(this->fileStream, start_pos + size, SEEK_SET);
	safefree(chunk);
}

static void SmackerResource_destroyAudio (SmackerResource* this)
{
	if (!this->audio) return;
		
	SDL_LockAudio();

	SmackerAudio** hooked_audio = (SmackerAudio**)Mix_GetMusicHookData();
	if (*hooked_audio == this->audio)
		*hooked_audio = NULL;

	SDL_UnlockAudio();

	while (this->audio->earliestLink) {
		BufferLink* old_link = this->audio->earliestLink;
		this->audio->earliestLink = old_link->nextLink;
		safefree(old_link->buf);
		safefree(old_link);
	}
	safefree(this->audio);
	this->audio = NULL;
}

void SmackerResource_destroy (SmackerResource* this)
{
	safefree(this->frameSizes);
	safefree(this->frameTypes);
	BigTree_destroy(this->MMapTree);
	BigTree_destroy(this->MClrTree);
	BigTree_destroy(this->FullTree);
	BigTree_destroy(this->TypeTree);
	SmackerResource_destroyAudio(this);
	safefree(this->cvt);
	safefree(this);
}

#endif
