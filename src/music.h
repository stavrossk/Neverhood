/*
// music.h
// things to share between MusicResource and SmackerResource to mix their audio together
*/

#ifndef __MUSIC_H__
#define __MUSIC_H__

#include <helper.h>
#include <SDL/SDL.h>

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

#endif