#include "fpga_api.h"
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <cstring>
#include <cmath>

FPGA::FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size)
{
  m_size_ = m_size;
  v_size_ = v_size;
  data_size_ = (m_size_ + 1) * v_size_; // fpga bram data size

  fd_ = open("/dev/mem", O_RDWR);
  qdata_ = static_cast<int8_t *>(mmap(NULL, data_size_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, data_addr));
  output_ = static_cast<unsigned int *>(mmap(NULL, sizeof(unsigned int), PROT_READ | PROT_WRITE, MAP_SHARED, fd_, output_addr));

  num_block_call_ = 0;
}

FPGA::~FPGA()
{
  munmap(qdata_, data_size_);
  munmap(output_, sizeof(unsigned int));
  close(fd_);
}

int8_t *FPGA::qmatrix(void)
{
  return qdata_ + v_size_;
}

int8_t *FPGA::qvector(void)
{
  return qdata_;
}

void FPGA::reset(void)
{
  num_block_call_ = 0;
}

int FPGA::num_block_call(void)
{
  return num_block_call_;
}

static void quantize(const float* input, int8_t* quantized, int num_input, float scale)
{
  for(int i = 0; i < num_input; i++)
  {
    int16_t x = static_cast<int16_t>(ceilf(input[i] / scale));
    quantized[i] = x > 127 ? 127 : x < -128 ? -128 : x;
  }
}

static void dequantize(int32_t* quantized, float* output, int num_output, float scale)
{
  for(int i = 0; i < num_output; i++)
  {
    output[i] = scale * static_cast<float>(quantized[i]);
  }
}

const int16_t *FPGA::qblockMV(Compute* comp)
{
  num_block_call_ += 1;

  // fpga version
  volatile uint32_t *ip_status = output_;

  *ip_status = 0x5555;
  while (*ip_status == 0x5555);

  return reinterpret_cast<int16_t *>(qdata_);
}

void FPGA::largeMV(const int8_t *large_mat, const float *input, float *output, int num_input, int num_output, Compute* comp)
{
  // TODO: large_mat is quantized already
  // TODO: Profiling and optimization

  int8_t *qvec = this->qvector();
  int8_t *qmat = this->qmatrix();

  const int8_t *qlarge_mat = large_mat;
  int8_t *qinput = new int8_t[num_input];
  int32_t *qoutput = new int32_t[num_output];

  // NOTE: We'll ignore comp->act_bits and comp->weight_bits variable and
  // always quantize into 8bit signed integer

  float act_scale = (comp->act_max - comp->act_min)/127.0f;
  float weight_scale = (comp->weight_max - comp->weight_min)/127.0f;

  quantize(input, qinput, num_input, act_scale);

  // 0) Initialize output vector
  for (int i = 0; i < num_output; ++i)
    qoutput[i] = 0;

  for (int i = 0; i < num_output; i += m_size_)
  {
    for (int j = 0; j < num_input; j += v_size_)
    {
      // 0) Initialize input vector
      int block_row = min(m_size_, num_output - i);
      int block_col = min(v_size_, num_input - j);

      // 1) Assign a vector
      int k = 0;
      for (; k < block_col; ++k) { qvec[k] = qinput[j + k]; }
      for (; k < v_size_; ++k) { qvec[k] = 0; }

      // 2) Assign a matrix
      int row = 0;
      for (; row < block_row; ++row) {
        int col = 0;
        for (; col < block_col; ++col) {
          qmat[v_size_*row + col] = qlarge_mat[num_input*(i + row) + j + col];
        }
        for (; col < v_size_; ++col) {
          qmat[v_size_*row + col] = 0;
        }
      }
      for (; row < m_size_; ++row) {
        for (int col = 0; col < v_size_; ++col) {
          qmat[v_size_*row + col] = 0;
        }
      }

      // 3) Call a function `qblockMV() to execute MV multiplication
      const int16_t* ret = this->qblockMV(comp);

      // 4) Accumulate intermediate results
      for(int row = 0; row < block_row; ++row)
        qoutput[i + row] += ret[row];
    }
  }

  dequantize(qoutput, output, num_output, act_scale*weight_scale);

  delete[] qinput;
  delete[] qoutput;
}

void FPGA::convLowering(const std::vector<std::vector<std::vector<std::vector<int8_t>>>> &cnn_weights,
                        std::vector<std::vector<int8_t>> &new_weights,
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
