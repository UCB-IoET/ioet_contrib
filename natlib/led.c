
#include <stdint.h>
#include <stdlib.h>

#define BASE 0x400E1000
#define SET 0x54
#define CLEAR 0x58

uint32_t volatile * set   = (uint32_t volatile *)(BASE + SET);
uint32_t volatile * clear = (uint32_t volatile *)(BASE + CLEAR);

struct LED_Strip {
  uint16_t *led;
  uint16_t size;
  uint32_t sclk;
  uint32_t sdo;
};

struct LED_Strip * LED_init(uint16_t size, uint32_t sclk, uint32_t sdo)
{
  printf("Start of LED_init\n");
  int i;
  struct LED_Strip * strip = malloc(sizeof(struct LED_Strip));
  strip->size = size;
  strip->sclk = sclk;
  strip->sdo = sdo;
  strip->led = malloc(sizeof(uint16_t)*size);
  for(i = 0; i < strip->size; i++) {
    strip->led[i] = 0;
  }
  LED_show(strip);
  return strip;
}

void LED_set(struct LED_Strip * strip, int i, char r, char g, char b)
{
  strip->led[i] = (r<<10) + (g<<5) + b;
}

void LED_show(struct LED_Strip * strip)
{
  printf("Start of LED_show %d 0x%x 0x%x\n", strip->size, strip->sclk, strip->sdo);
  uint32_t SCLK = strip->sclk;
  uint32_t SDO  = strip->sdo;
 
  uint32_t nDots = strip->size; // number of lights in strip  
  
  char mask = 0x10; // mask for data transmission
  uint32_t i,j,k;

  *clear = SCLK;
  *clear = SDO;
  for(i=0; i<32; i++){
    *set   = SCLK;
    *clear = SCLK;
  }
  
  for (k=0; k<nDots; k++){
    char dr = ((strip->led[k]>>10) & 0x1f); // red data   (0 - 31)
    char dg = ((strip->led[k]>>5) & 0x1f); // green data (0 - 31)
    char db = (strip->led[k] & 0x1f); // blue data  (0 - 31)
    mask = 0x10;
    *set   = SDO;
    *set   = SCLK;
    *clear = SCLK;
    // output 5 bits of color data (red, green then blue)
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

  for(i=0; i<nDots;i++){
    *set = SCLK;
    *clear = SCLK;
  }
}
