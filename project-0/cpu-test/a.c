#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>

enum { SIZE = 64 };

int main(void) {
  int mem = open("/dev/mem", O_RDWR | O_NONBLOCK);
  volatile int *fpga_bram = mmap(NULL, (SIZE + 1) * SIZE * sizeof(int), PROT_WRITE, MAP_SHARED, mem, 0x40000000);
  volatile int *fpga_ip   = mmap(NULL, sizeof(int), PROT_WRITE, MAP_SHARED, mem, 0x43C00000);

  // Initialize input vector
  for (int i = 0; i < SIZE; ++i) {
    fpga_bram[i] = i;
  }
  // Initialize input matrix
  for (int row = 0; row < SIZE; ++row) {
    for (int col = 0; col < SIZE; ++col) {
      fpga_bram[SIZE + row*SIZE + col] = row*SIZE + col;
    }
  }

  // Run IP
  *fpga_ip = 0x5555;
  while (*fpga_ip == 0x5555);

  // Read output
  printf("result = {\n");
  for (int i = 0; i < SIZE; ++i) {
    printf("  %d,\n", fpga_bram[i]);
  }
  printf("}\n");
}
