#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <fcntl.h>
#include <sys/mman.h>

enum { SIZE = 64 };

int main(void) {
  int mem = open("/dev/mem", O_RDWR | O_NONBLOCK);
  volatile int8_t *fpga_bram = mmap(NULL, (SIZE + 1) * SIZE, PROT_WRITE, MAP_SHARED, mem, 0x40000000);
  volatile int *fpga_ip = mmap(NULL, sizeof(int), PROT_WRITE, MAP_SHARED, mem, 0x43C00000);

  // Initialize input vector
  for (int i = 0; i < SIZE; ++i) {
    fpga_bram[i] = 1 + i;
  }
  // Initialize input matrix
  for (int row = 0; row < SIZE; ++row) {
    for (int col = 0; col < SIZE; ++col) {
      fpga_bram[SIZE + row*SIZE + col] = row*2 + col*2/SIZE - SIZE;
    }
  }

  printf("before:\n");
  for (int i = 0; i < 4180; ++i) {
    if (i % 8 == 0) { printf(" "); }
    if (i % 64 == 0) { printf("\n"); }
    if (i == SIZE) { printf("\n"); }
    printf("%02" PRIx32, (uint32_t)(uint8_t)fpga_bram[i]);
  }
  printf("...\n\n");

  // Run IP
  fpga_ip[0] = 0x5555;
  while (fpga_ip[0] == 0x5555);

  printf("after:\n");
  for (int i = 0; i < 4180; ++i) {
    if (i % 8 == 0) { printf(" "); }
    if (i % 64 == 0) { printf("\n"); }
    if (i == SIZE) { printf("\n"); }
    printf("%02" PRIx32, (uint32_t)(uint8_t)fpga_bram[i]);
  }
  printf("...\n\n");

  volatile int16_t *fpga_result = (volatile int16_t *)fpga_bram;
  // Read output
  printf("[");
  for (int i = 0; i < SIZE; ++i) {
    printf("[%6" PRId16 "]%s", fpga_result[i], i == SIZE - 1 ? "]\n" : "\n ");
  }
}
