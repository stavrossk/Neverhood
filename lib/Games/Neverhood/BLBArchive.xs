/*
// BLBArchive - opens BLB archives and makes resources from them
// Based on the ScummVM Neverhood Engine's BLB archive code
// Copyright (C) 2012  Blaise Roth
// See the LICENSE file for the full terms of the license.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <SDL/SDL.h>

typedef struct {

} BLBArchive;

BLBArchive* BLBArchive_new(const char* filename) {
	BLBArchive* this = safemalloc(sizeof(BLBArchive));

	return this;
}

MODULE = Games::Neverhood::BLBArchive		PACKAGE = Games::Neverhood::BLBArchive		PREFIX = Neverhood_BLBArchive_

BLBArchive*
Neverhood_BLBArchive_new(CLASS, filename)
		const char* CLASS
		const char* filename
	INIT:
		CLASS = "Games::Neverhood::BLBArchive";
	CODE:
		RETVAL = BLBArchive_new(filename);
	OUTPUT:
		RETVAL
