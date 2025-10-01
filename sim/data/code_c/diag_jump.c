#include <stdint.h>

//#define DM_BASE  0x10001000u
#define DM_BASE  0x80000000u
static volatile uint32_t * const OUT = (volatile uint32_t *)DM_BASE;

#define MARK(TAG)           (OUT[7] = (uint32_t)(TAG))
#define PAYLOAD(TAG)        (OUT[0] = (uint32_t)(TAG))
#define MARK_BOTH(TAG)      do { MARK(TAG); PAYLOAD(TAG); } while (0)

static volatile uint32_t g_one  = 1u;   
static volatile uint32_t g_flag = 1u;   

int main(void) {
  /* clear */
  OUT[0]=OUT[1]=OUT[2]=OUT[3]=OUT[4]=OUT[5]=0u;
  MARK_BOTH(0x00000000u);

  MARK_BOTH(0xAAA10001u);
  if (g_one == 0u) {                    
    OUT[1] = 0xBAD00000u;
    OUT[1] = 0xBAD00001u;
    OUT[1] = 0xBAD00002u;
  }
  OUT[1] = 0x55530003u;                  
  MARK_BOTH(0x55510001u);

  MARK_BOTH(0xAAA20002u);
  uint32_t f = g_flag;                 
  if (f != 0u) {
    OUT[2] = 0x22220002u;               
  } else {
    OUT[2] = 0x2222FFF0u;                
  }
  MARK_BOTH(0x55520002u);

  MARK_BOTH(0xAAA30003u);
  OUT[4] = 0x12345678u;                  
  uint32_t echo = OUT[4];                
  OUT[3] = echo;                       
  MARK_BOTH(0x55530003u);

  MARK_BOTH(0xAAA40004u);
  uint32_t i = 0u;
  while (1) {
    i++;
    if (i == 3u) break;                  // back-edge branch
  }
  OUT[5] = i;                            // = 3
  MARK_BOTH(0x55540004u);

  MARK_BOTH(0xDEAD5100u);
  return 0;
}

