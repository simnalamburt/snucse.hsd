#include "fpga_api.h"
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <cstring>

#define min(x, y) (((x) < (y)) ? (x) : (y))

FPGA::FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size)
{
  m_size_ = m_size;
  v_size_ = v_size;
  data_size_ = (m_size_ + 1) * v_size_ * sizeof(float); // fpga bram data size

  fd_ = open("/dev/mem", O_RDWR);
  data_ = static_cast<float *>(mmap(NULL, data_size_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, data_addr));
  output_ = static_cast<unsigned int *>(mmap(NULL, sizeof(unsigned int), PROT_READ | PROT_WRITE, MAP_SHARED, fd_, output_addr));

  num_block_call_ = 0;
}

FPGA::~FPGA()
{
  munmap(data_, data_size_);
  munmap(output_, sizeof(unsigned int));
  close(fd_);
}

float *FPGA::matrix(void)
{
  return data_ + v_size_;
}

float *FPGA::vector(void)
{
  return data_;
}

void FPGA::reset(void)
{
  num_block_call_ = 0;
}

int FPGA::num_block_call(void)
{
  return num_block_call_;
}

const float *__attribute__((optimize("O0"))) FPGA::blockMV()
{
  num_block_call_ += 1;

  // fpga version
  *output_ = 0x5555;
  while (*output_ == 0x5555)
    ;

  return data_;
}

void FPGA::largeMV(const float *large_mat, const float *input, float *output, int num_input, int num_output)
{
  float *vec = this->vector();
  float *mat = this->matrix();

  // 0) Initialize output vector
  for (int i = 0; i < num_output; ++i)
    output[i] = 0;

  for (int i = 0; i < num_output; i += m_size_)
  {
    for (int j = 0; j < num_input; j += v_size_)
    {
      // 0) Initialize input vector
      int block_row = min(m_size_, num_output - i);
      int block_col = min(v_size_, num_input - j);

      // 1) Assign a vector
      int k = 0;
      for (; k < block_col; ++k) { vec[k] = input[j + k]; }
      for (; k < v_size_; ++k) { vec[k] = 0; }

      // 2) Assign a matrix
      int row = 0;
      for (; row < block_row; ++row) {
        int col = 0;
        for (; col < block_col; ++col) {
          mat[v_size_*row + col] = large_mat[num_input*(i + row) + j + col];
        }
        for (; col < v_size_; ++col) {
          mat[v_size_*row + col] = 0;
        }
      }
      for (; row < m_size_; ++row) {
        for (int col = 0; col < v_size_; ++col) {
          mat[v_size_*row + col] = 0;
        }
      }

      // 3) Call a function `blockMV() to execute MV multiplication
      const float *ret = this->blockMV();

      // 4) Accumulate intermediate results
      for (int row = 0; row < block_row; ++row)
        output[i + row] += ret[row];
    }
  }
}

void FPGA::convLowering(const std::vector<std::vector<std::vector<std::vector<float>>>> &cnn_weights,
                        std::vector<std::vector<float>> &new_weights,
                        const std::vector<std::vector<std::vector<float>>> &inputs,
                        std::vector<std::vector<float>> &new_inputs)
{
  /*
   * Arguments:
   *
   * conv_weights: [conv_channel, input_channel, conv_height, conv_width]
   * new_weights: [conv_channel, input_channel*conv_height*conv_width]
   * inputs: [input_channel, input_height, input_width]
   * new_inputs: [input_channel*conv_height*conv_width, (input_height-conv_height+1)*(input_width-conv_width+1)]
   *
   */

  int conv_channel = cnn_weights.size();
  int input_channel = cnn_weights[0].size();
  int conv_height = cnn_weights[0][0].size();
  int conv_width = cnn_weights[0][0][0].size();
  //int input_channel = inputs.size();
  int input_height = inputs[0].size();
  int input_width = inputs[0][0].size();

  for (int row = 0; row < conv_channel; ++row) {
    for (int z = 0; z < input_channel; ++z) {
      for (int y = 0; y < conv_height; ++y) {
        for (int x = 0; x < conv_width; ++x) {
          new_weights[row][z*conv_height*conv_width + y*conv_width + x] = cnn_weights[row][z][y][x];
        }
      }
    }
  }

  const int row_count = input_height - conv_height + 1;
  const int col_count = input_width - conv_width + 1;
  for (int z = 0; z < input_channel; ++z) {
    for (int y = 0; y < conv_height; ++y) {
      for (int x = 0; x < conv_width; ++x) {
        for (int offset_y = 0; offset_y < row_count; ++offset_y) {
          for (int offset_x = 0; offset_x < col_count; ++offset_x) {
            new_inputs[z*conv_height*conv_width + y*conv_width + x][offset_y*col_count + offset_x] = inputs[z][offset_y + y][offset_x + x];
          }
        }
      }
    }
  }
}
