/*
// BLBArchive - opens BLB archives and returns handles to the files inside
// Based on the ScummVM Neverhood Engine's BLB archive code
// Copyright (C) 2012  Blaise Roth
// See the LICENSE file for the full terms of the license.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <helper.h>
#include <resource.h>
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

typedef struct {

} BLBArchive;

MODULE = Games::Neverhood::BLBArchive		PACKAGE = Games::Neverhood::BLBArchive		PREFIX = Neverhood_BLBArchive_

