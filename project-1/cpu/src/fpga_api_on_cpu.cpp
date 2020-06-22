#include "fpga_api.h"
#include <stdio.h>
#include <iostream>
#include <cstring>
#include <cmath>

using namespace std;

#define min(x, y) (((x) < (y)) ? (x) : (y))

FPGA::FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size)
{
  m_size_ = m_size;
  v_size_ = v_size;
  data_size_ = (m_size_ + 1) * v_size_; // fpga bram data size

  qvec_ = new int8_t[v_size_];
  qmat_ = new int8_t[m_size_*v_size_];
  qout_ = new short[m_size_];

  output_ = new unsigned int[m_size_]; // use output_ as tempolar output
  data_ = new float[data_size_];

  num_block_call_ = 0;
}

FPGA::~FPGA()
{
  delete[] output_;
  delete[] data_;
  delete[] qvec_;
  delete[] qmat_;
  delete[] qout_;
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

static void quantize(float* input, int8_t* quantized, int num_input, float scale)
{
  for(int i = 0; i < num_input; i++)
  {
    int16_t x = static_cast<int16_t>(ceilf(input[i] / scale));
    quantized[i] = x > 127 ? 127 : x < -128 ? -128 : x;
  }
}

static void dequantize(short* quantized, float* output, int num_output, float scale)
{
  for(int i = 0; i < num_output; i++)
  {
    output[i] = scale * static_cast<float>(quantized[i]);
  }
}

const float *FPGA::blockMV(Compute* comp)
{
  num_block_call_ += 1;

  // cpu version
  float *vec = this->vector();
  float *mat = this->matrix();
  float *out = reinterpret_cast<float *>(output_);

  if(comp->quantized)
  {
    // NOTE: We'll ignore comp->act_bits and comp->weight_bits variable and
    // always quantize into 8bit signed integer

    float act_scale = (comp->act_max - comp->act_min)/127.0f;
    float weight_scale = (comp->weight_max - comp->weight_min)/127.0f;

    quantize(vec, qvec_, v_size_, act_scale);
    quantize(mat, qmat_, m_size_*v_size_, weight_scale);

    for (int i = 0; i < m_size_; ++i)
    {
      short sum = 0;
      // NOTE: Overflow may occurs here during accumulation, but we'll ignore it
      for (int j = 0; j < v_size_; ++j)
        sum += qvec_[j] * qmat_[v_size_ * i + j];
      qout_[i] = sum;
    }

    dequantize(qout_, out, m_size_, act_scale*weight_scale);
  }
  else
  {
    for (int i = 0; i < m_size_; ++i)
    {
      out[i] = 0;
      for (int j = 0; j < v_size_; ++j)
        out[i] += vec[j] * mat[v_size_ * i + j];
    }
  }

  for (int i = 0; i < m_size_; ++i)
    data_[i] = out[i];

  return data_;
}

void FPGA::largeMV(const float *large_mat, const float *input, float *output, int num_input, int num_output, Compute* comp)
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
      const float *ret = this->blockMV(comp);

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
