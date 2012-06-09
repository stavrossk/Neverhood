#ifndef __HELPER_H__
#define __HELPER_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>

void error(const char* format, ...) {
	printf(format);
	printf("\n");
	exit(1);
}

void debug(const char* format, ...) {
	if(SvTRUE(get_sv("Games::Neverhood::Debug", 0))) {
		printf(format);
		printf("\n");
	}
}

#endif
