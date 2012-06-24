/*
// smacker.h
// bitstream and huffman trees for the smacker resource
*/

#ifndef __SMACKER_H__
#define __SMACKER_H__

#include <SDL/SDL.h>
#include <assert.h>

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

BitStream* BitStream_new(Uint8* buf, Uint32 length) {
	BitStream* this = safemalloc(sizeof(BitStream));
	this->_buf = buf;
	this->_end = buf + length;
	this->_bitCount = 8;
	this->_curByte = *this->_buf++;

	return this;
}

Uint8 BitStream_getBit(BitStream* this) {
	if (this->_bitCount == 0) {
		assert(this->_buf < this->_end);
		this->_curByte = *this->_buf++;
		this->_bitCount = 8;
	}

	Uint8 v = this->_curByte & 1;

	this->_curByte >>= 1;
	this->_bitCount--;

	return v;
}

Uint8 BitStream_get8(BitStream* this) {
	assert(this->_buf < this->_end);

	Uint8 v = (*this->_buf << this->_bitCount) | this->_curByte;
	this->_curByte = *this->_buf++ >> (8 - this->_bitCount);

	return v;
}

Uint8 BitStream_peek8(BitStream* this) {
	if (this->_buf == this->_end)
		return this->_curByte;

	assert(this->_buf < this->_end);
	return (*this->_buf << this->_bitCount) | this->_curByte;
}

void BitStream_skip(BitStream* this, int n) {
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

#define SMK_SMALL_NODE 0x8000

typedef struct {
	Uint16 _treeSize;
	Uint16 _tree[511];

	Uint16 _prefixtree[256];
	Uint8 _prefixlength[256];
} SmallTree;

static Uint16 SmallTree_decodeTree(SmallTree* this, BitStream* bs, Uint32 prefix, int length);

SmallTree* SmallTree_new(BitStream* bs) {
	SmallTree* this = safemalloc(sizeof(SmallTree));
	this->_treeSize = 0;

	Uint8 bit = BitStream_getBit(bs);
	assert(bit);

	int i;
	for (i = 0; i < 256; i++)
		this->_prefixtree[i] = this->_prefixlength[i] = 0;

	SmallTree_decodeTree(this, bs, 0, 0);

	bit = BitStream_getBit(bs);
	assert(!bit);

	return this;
}

static Uint16 SmallTree_decodeTree(SmallTree* this, BitStream* bs, Uint32 prefix, int length) {
	if (!BitStream_getBit(bs)) { // Leaf
		this->_tree[this->_treeSize] = BitStream_get8(bs);

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

	Uint16 r1 = SmallTree_decodeTree(this, bs, prefix, length + 1);

	this->_tree[t] = SMK_SMALL_NODE | r1;

	Uint16 r2 = SmallTree_decodeTree(this, bs, prefix | (1 << length), length + 1);

	return r1 + r2 + 1;
}

Uint16 SmallTree_getCode(SmallTree* this, BitStream* bs) {
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

#define SMK_BIG_NODE 0x80000000

typedef struct {
	Uint32  _treeSize;
	Uint32* _tree;
	Uint32  _last[3];

	Uint32 _prefixtree[256];
	Uint8 _prefixlength[256];

	/* Used during construction */
	Uint32 _markers[3];
	SmallTree* _loBytes;
	SmallTree* _hiBytes;
} BigTree;

static Uint32 BigTree_decodeTree(BigTree* this, BitStream* bs, Uint32 prefix, int length);

BigTree* BigTree_new(BitStream* bs, int allocSize) {
	BigTree* this = safemalloc(sizeof(BigTree));

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

	BigTree_decodeTree(this, bs, 0, 0);

	Uint8 bit = BitStream_getBit(bs);
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

void BigTree_destroy(BigTree* this) {
	safefree(this->_tree);
	safefree(this);
}

void BigTree_reset(BigTree* this) {
	this->_tree[this->_last[0]] = this->_tree[this->_last[1]] = this->_tree[this->_last[2]] = 0;
}

static Uint32 BigTree_decodeTree(BigTree* this, BitStream* bs, Uint32 prefix, int length) {
	if (!BitStream_getBit(bs)) { // Leaf
		Uint32 lo = SmallTree_getCode(this->_loBytes, bs);
		Uint32 hi = SmallTree_getCode(this->_hiBytes, bs);

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

	Uint32 r1 = BigTree_decodeTree(this, bs, prefix, length + 1);

	this->_tree[t] = SMK_BIG_NODE | r1;

	Uint32 r2 = BigTree_decodeTree(this, bs, prefix | (1 << length), length + 1);

	return r1 + r2 + 1;
}

Uint32 BigTree_getCode(BigTree* this, BitStream* bs) {
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

#endif
