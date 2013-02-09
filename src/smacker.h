/*
// smacker.h
// bitstream and huffman trees for the smacker resource
*/

#ifndef __SMACKER__
#define __SMACKER__

#include <helper.h>
#include <SDL/SDL.h>
#include <assert.h>

/*
// class BitStream
// Little-endian bit stream provider.
*/

typedef struct {
	Uint8* buf;
	Uint8* end;
	Uint8  curByte;
	Uint8  bitCount;
} BitStream;

BitStream* BitStream_new (Uint8* buf, Uint32 size)
{
	BitStream* this = safemalloc(sizeof(BitStream));
	this->buf = buf;
	this->end = buf + size;
	this->bitCount = 8;
	this->curByte = *this->buf++;

	return this;
}

bool BitStream_getBit (BitStream* this)
{
	if (this->bitCount == 0) {
		assert(this->buf < this->end);
		this->curByte = *this->buf++;
		this->bitCount = 8;
	}

	bool v = this->curByte & 1;

	this->curByte >>= 1;
	this->bitCount--;

	return v;
}

Uint8 BitStream_get8 (BitStream* this)
{
	assert(this->buf < this->end);

	Uint8 v = (*this->buf << this->bitCount) | this->curByte;
	this->curByte = *this->buf++ >> (8 - this->bitCount);

	return v;
}

Uint8 BitStream_peek8 (BitStream* this)
{
	if (this->buf == this->end)
		return this->curByte;

	assert(this->buf < this->end);
	return (*this->buf << this->bitCount) | this->curByte;
}

void BitStream_skip (BitStream* this, int n)
{
	assert(n <= 8);
	this->curByte >>= n;

	if (this->bitCount >= n) {
		this->bitCount -= n;
	} else {
		assert(this->buf < this->end);
		this->bitCount = this->bitCount + 8 - n;
		this->curByte = *this->buf++ >> (8 - this->bitCount);
	}
}

/*
// class SmallTree
// A Huffman-tree to hold 8-bit values.
*/

#define SMK_SMALL_NODE 0x8000

typedef struct {
	Uint16 treeSize;
	Uint16 tree[511];

	Uint16 prefixTree[256];
	Uint8  prefixSize[256];
} SmallTree;

static Uint16 SmallTree_decodeTree (SmallTree* this, BitStream* bs, Uint32 prefix, int size);

SmallTree* SmallTree_new (BitStream* bs)
{
	SmallTree* this = safemalloc(sizeof(SmallTree));
	this->treeSize = 0;

	bool bit = BitStream_getBit(bs);
	assert(bit);

	int i;
	for (i = 0; i < 256; i++)
		this->prefixTree[i] = this->prefixSize[i] = 0;

	SmallTree_decodeTree(this, bs, 0, 0);

	bit = BitStream_getBit(bs);
	assert(!bit);

	return this;
}

static Uint16 SmallTree_decodeTree (SmallTree* this, BitStream* bs, Uint32 prefix, int size)
{
	if (!BitStream_getBit(bs)) { // Leaf
		this->tree[this->treeSize] = BitStream_get8(bs);	

		if (size <= 8) {
			int i;
			for (i = 0; i < 256; i += (1 << size)) {
				this->prefixTree[prefix | i] = this->treeSize;
				this->prefixSize[prefix | i] = size;
			}
		}
		this->treeSize++;

		return 1;
	}

	Uint16 t = this->treeSize++;

	if (size == 8) {
		this->prefixTree[prefix] = t;
		this->prefixSize[prefix] = 8;
	}

	Uint16 r1 = SmallTree_decodeTree(this, bs, prefix, size + 1);

	this->tree[t] = SMK_SMALL_NODE | r1;

	Uint16 r2 = SmallTree_decodeTree(this, bs, prefix | (1 << size), size + 1);

	return r1 + r2 + 1;
}

Uint16 SmallTree_getCode (SmallTree* this, BitStream* bs)
{
	Uint8 peek = BitStream_peek8(bs);
	Uint16* p = &this->tree[this->prefixTree[peek]];
	BitStream_skip(bs, this->prefixSize[peek]);

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

#define SMK_BIG_NODE 0x80000000

typedef struct {
	Uint32  treeSize;
	Uint32* tree;
	Uint32  last[3];

	Uint32 prefixTree[256];
	Uint8  prefixSize[256];

	/* Used during construction */
	Uint32 markers[3];
	SmallTree* loBytes;
	SmallTree* hiBytes;
} BigTree;

static Uint32 BigTree_decodeTree (BigTree* this, BitStream* bs, Uint32 prefix, int size);

BigTree* BigTree_new (BitStream* bs, int allocSize)
{
	BigTree* this = safemalloc(sizeof(BigTree));

	if (!BitStream_getBit(bs)) {
		this->tree = safemalloc(sizeof(Uint32));
		this->tree[0] = 0;
		this->last[0] = this->last[1] = this->last[2] = 0;
		return this;
	}

	int i;
	for (i = 0; i < 256; i++)
		this->prefixTree[i] = this->prefixSize[i] = 0;

	this->loBytes = SmallTree_new(bs);
	this->hiBytes = SmallTree_new(bs);

	this->markers[0] = BitStream_get8(bs) | (BitStream_get8(bs) << 8);
	this->markers[1] = BitStream_get8(bs) | (BitStream_get8(bs) << 8);
	this->markers[2] = BitStream_get8(bs) | (BitStream_get8(bs) << 8);

	this->last[0] = this->last[1] = this->last[2] = 0xffffffff;

	this->treeSize = 0;
	this->tree = safemalloc(sizeof(Uint32) * (allocSize / 4));

	BigTree_decodeTree(this, bs, 0, 0);

	bool bit = BitStream_getBit(bs);
	assert(!bit);

	for (i = 0; i < 3; i++) {
		if (this->last[i] == 0xffffffff) {
			this->last[i] = this->treeSize;
			this->tree[this->treeSize++] = 0;
		}
	}

	safefree(this->loBytes);
	safefree(this->hiBytes);

	return this;
}

void BigTree_destroy (BigTree* this)
{
	safefree(this->tree);
	safefree(this);
}

void BigTree_reset (BigTree* this) {
	this->tree[this->last[0]] = this->tree[this->last[1]] = this->tree[this->last[2]] = 0;
}

static Uint32 BigTree_decodeTree (BigTree* this, BitStream* bs, Uint32 prefix, int size)
{
	if (!BitStream_getBit(bs)) { // Leaf
		Uint32 lo = SmallTree_getCode(this->loBytes, bs);
		Uint32 hi = SmallTree_getCode(this->hiBytes, bs);

		Uint32 v = (hi << 8) | lo;

		this->tree[this->treeSize] = v;

		int i;
		if (size <= 8) {
			for (i = 0; i < 256; i += (1 << size)) {
				this->prefixTree[prefix | i] = this->treeSize;
				this->prefixSize[prefix | i] = size;
			}
		}

		for (i = 0; i < 3; i++) {
			if (this->markers[i] == v) {
				this->last[i] = this->treeSize;
				this->tree[this->treeSize] = 0;
			}
		}
		this->treeSize++;

		return 1;
	}

	Uint32 t = this->treeSize++;

	if (size == 8) {
		this->prefixTree[prefix] = t;
		this->prefixSize[prefix] = 8;
	}

	Uint32 r1 = BigTree_decodeTree(this, bs, prefix, size + 1);

	this->tree[t] = SMK_BIG_NODE | r1;

	Uint32 r2 = BigTree_decodeTree(this, bs, prefix | (1 << size), size + 1);

	return r1 + r2 + 1;
}

Uint32 BigTree_getCode (BigTree* this, BitStream* bs)
{
	Uint8 peek = BitStream_peek8(bs);
	Uint32* p = &this->tree[this->prefixTree[peek]];
	BitStream_skip(bs, this->prefixSize[peek]);

	while (*p & SMK_BIG_NODE) {
		if (BitStream_getBit(bs))
			p += *p & ~SMK_BIG_NODE;
		p++;
	}

	Uint32 v = *p;
	if (v != this->tree[this->last[0]]) {
		this->tree[this->last[2]] = this->tree[this->last[1]];
		this->tree[this->last[1]] = this->tree[this->last[0]];
		this->tree[this->last[0]] = v;
	}

	return v;
}

#endif
