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

  // Run IP
  fpga_ip[0] = 0x5555;
  while (fpga_ip[0] == 0x5555);

  volatile int16_t *fpga_result = (volatile int16_t *)fpga_bram;
  // Read output
  printf("result = {\n");
  for (int i = 0; i < SIZE; ++i) {
    printf("  %" PRId16 ",\n", fpga_result[i]);
  }
  printf("}\n");
}
