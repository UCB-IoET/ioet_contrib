//
//  svcd_write.h
//  Testing Suite for the SVCD write function


#ifndef __SVCD__write__
#define __SVCD__write__

#include <stdio.h>
#include "string.h"
#include "stdint.h"
#include <string.h>
#include "inttypes.h"


void svcd_write(char* targetip, uint8_t svcid, uint8_t attrid, 
    char* payload, uint8_t timeout_ms, char* on_done);


#endif /* defined(__SVCD__write__) */
