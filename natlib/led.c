/*
 *Supernight LED strip library
 *Authors: Jose Oyola, Jochem van Gaalen, Naren Vasanad
 *Notes: LEDs are addressed in groups of 3
 *       Need to update all LEDs in the chain and hence requires state 
 *       of each LED to be stored in an array
*/

#include <stdint.h>
#include <stdlib.h>

// Base addresses as per data sheet for ATMEL
// Used LED_SET and LED_CLEAR as Output Value rather than Output Driver register
#define LED_BASE 0x400E1000
#define LED_SET 0x54
#define LED_CLEAR 0x58

uint32_t volatile * set   = (uint32_t volatile *)(LED_BASE + LED_SET);
uint32_t volatile * clear = (uint32_t volatile *)(LED_BASE + LED_CLEAR);

/*
 *LED_Strip object has four parts
 *led : array of LEDs. Size depends on 'size'
 *size: size of the LED strip
 *sclk: pin to which SCLK is connected. Should be given as 1<<X where X is pin number
 *sdo: pin to which SDO is connected. Same format as 'sclk'
*/
struct LED_Strip {
  uint16_t *led;
  uint16_t size;
  uint32_t sclk;
  uint32_t sdo;
};

// init function for LEDs
struct LED_Strip * LED_init(uint16_t size, uint32_t sclk, uint32_t sdo)
{
  int i;
  // Create a new strip and allocate memory for it
  struct LED_Strip * strip = malloc(sizeof(struct LED_Strip));
  strip->size = size;
  strip->sclk = sclk;
  strip->sdo = sdo;
  // Allocate memory for the LED array
  strip->led = malloc(sizeof(uint16_t)*size);
  for(i = 0; i < strip->size; i++) {
    strip->led[i] = 0;
  }
  // 'led' contains 0s and hence LED_show() would clear these LEDs
  LED_show(strip);
  return strip;
}

// set a particular LED
void LED_set(struct LED_Strip * strip, int i, char r, char g, char b)
{
  // The format for LEDs is 5 bits each for red, green and blue
  // Mask it so that each color is only five bits
  r &= 0x1f;
  g &= 0x1f;
  b &= 0x1f;
  strip->led[i] = (r<<10) + (g<<5) + b;
}

// update the LED strip
// all signals are on rising edge
// this is why SCLK is first set and then cleared
void LED_show(struct LED_Strip * strip)
{
  uint32_t SCLK = strip->sclk;
  uint32_t SDO  = strip->sdo;
 
  uint32_t nDots = strip->size; // number of lights in strip  
  
  char mask = 0x10; // mask for data transmission
  uint32_t i,j,k;

  // send 32 bits of 0s initially according to data sheet
  *clear = SCLK;
  *clear = SDO;
  for(i=0; i<32; i++){
    *set   = SCLK;
    *clear = SCLK;
  }
  
  // for each LED in the strip
  for (k=0; k<nDots; k++){
    char dr = ((strip->led[k]>>10) & 0x1f); // red data   (0 - 31)
    char dg = ((strip->led[k]>>5) & 0x1f); // green data (0 - 31)
    char db = (strip->led[k] & 0x1f); // blue data  (0 - 31)
    mask = 0x10;
    *set   = SDO;
    *set   = SCLK;
    *clear = SCLK;
    // output 5 bits of color data in the order blue, red, green
    // get each bit starting with the MSB and send it over the data line
    for(j=0; j<5; j++){
      if((mask & db) != 0) *set = SDO;
      else *clear = SDO;

      *set = SCLK;
      *clear = SCLK;
      mask >>= 1;
    }
    mask = 0x10;
    for(j=0; j<5; j++){
      if((mask & dr) != 0) *set = SDO;
      else *clear = SDO;
     
      *set   = SCLK;
      *clear = SCLK;
      mask >>= 1;
    }
    mask = 0x10;
    //printf("Inside loop\n");
    for(j=0; j<5; j++){
      if((mask & dg) != 0) *set = SDO;
      else *clear = SDO;

      *set   = SCLK;
      *clear = SCLK;
      mask >>= 1;
    }
  }
  *clear = SDO;

  // at the end send 0s for as many LEDs that are on the strip
  for(i=0; i<nDots;i++){
    *set = SCLK;
    *clear = SCLK;
  }
}
