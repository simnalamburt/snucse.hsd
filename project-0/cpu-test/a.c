#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>

enum { SIZE = 64 };

int main(void) {
  int mem = open("/dev/mem", O_RDWR | O_NONBLOCK);
  volatile float *fpga_bram = mmap(NULL, (SIZE + 1) * SIZE * sizeof(float), PROT_WRITE, MAP_SHARED, mem, 0x40000000);
  volatile int *fpga_ip   = mmap(NULL, sizeof(int), PROT_WRITE, MAP_SHARED, mem, 0x43C00000);

  // Initialize input vector
  for (int i = 0; i < SIZE; ++i) {
    fpga_bram[i] = (float)i * 0.1f;
  }
  // Initialize input matrix
  for (int row = 0; row < SIZE; ++row) {
    for (int col = 0; col < SIZE; ++col) {
      fpga_bram[SIZE + row*SIZE + col] = (float)(row*SIZE + col) * 0.1f;
    }
  }

  // Run IP
  fpga_ip[0] = 0x5555;
  while (fpga_ip[0] == 0x5555);

  // Read output
  printf("result = {\n");
  for (int i = 0; i < SIZE; ++i) {
    printf("  %d,\n", fpga_bram[i]);
  }
  printf("}\n");
}

// for (int i = 0; fpga_ip[0] == 0x5555; ++i) {
//   if (i == 1000000) { i = 0; }
//   if (i != 0) { continue; }
//   printf("State: %d, Counter: %d\n", fpga_ip[1], fpga_ip[2]);
// }

// int max = 0;
// for (;;) {
//   int a = fpga_ip[2];
//   if (a > max) {
//     max = a;
//     printf("%d\n", max);
//   }
// }
