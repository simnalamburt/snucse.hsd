#include "fpga_api.h"
#include <cstdio>
#include <cstring>

#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#define DATA_SIZE SIZE*(SIZE+1)*sizeof(float) // fpga bram data size

#define min(x,y) (((x)<(y))?(x):(y))

FPGA::FPGA(off_t data_addr, off_t api_addr)
{
  fd_ = open("/dev/mem", O_RDWR);
  data_ = static_cast<float*>(mmap(NULL, DATA_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, fd_, data_addr));
  api_ = static_cast<unsigned int*>(mmap(NULL, sizeof(unsigned int), PROT_READ|PROT_WRITE, MAP_SHARED,fd_, api_addr));
}

FPGA::~FPGA()
{
  munmap(data_, DATA_SIZE );
  munmap(api_, sizeof(unsigned int));
  close(fd_);
}

float* FPGA::matrix(void)
{
  return data_ + SIZE;
}

float* FPGA::vector(void)
{
  return data_;
}

const float* __attribute__((optimize("O0"))) FPGA::run()
{
  *api_ = 0x5555;
  while(*api_ == 0x5555);

  return data_;
}

// Test code for bitstream
void FPGA::largeMV(const float* large_mat, const float* input, float* output, int num_input, int num_output)
{
  float* vec = this->vector();
  float* mat = this->matrix();

  // 0) Initialize output vector
  for(int i = 0; i < num_output ; ++i)
    output[i] = 0;

  for(int i = 0; i < num_output ; i += SIZE)
  {
    for(int j = 0; j < num_input ; j += SIZE)
    {
      // 0) Initialize input vector
      int n_remain = min(SIZE, num_output-i);
      int m_remain = min(SIZE, num_input-j);

      // 1) Assign a vector
      // IMPLEMENT THIS

      // 2) Assign a matrix
      // IMPLEMENT THIS

      // 3) Call a function `run() to execute MV multiplication
      const float* rst = this->run();

      // 4) Accumulate intermediate results
      for(int row = 0; row < n_remain; ++row)
        output[i + row] += rst[row];
    }
  }
}
