#include"fpga_api.h"
#include<cstring>
#include<stdio.h>

#define min(x,y) (((x)<(y))?(x):(y))

FPGA::FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size)
{
  m_size_ = m_size;
  v_size_ = v_size;
  data_size_ = (m_size_+1)*v_size_; // fpga bram data size
  num_block_call_ = 0;

  output_ = new unsigned int[m_size_];    // use output_ as tempolar output
  data_ = new float[data_size_];
}

FPGA::~FPGA()
{
  delete[] output_;
  delete[] data_;
}

float* FPGA::matrix(void)
{
  return data_ + v_size_;
}

float* FPGA::vector(void)
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

const float* FPGA::blockMV()
{
  num_block_call_ += 1;

  float* vec = this->vector();
  float* mat = this->matrix();
  float* out  = reinterpret_cast<float*>(output_);

  for(int i = 0; i < m_size_; ++i)
  {
    out[i] = 0;
    for(int j = 0; j < v_size_; ++j)
      out[i] += vec[j] * mat[v_size_*i + j];
  }

  for(int i = 0; i < m_size_; ++i)
  {
    data_[i] = out[i];
  }

  return data_;
}

void FPGA::largeMV(const float* large_mat, const float* input, float* output, int num_input, int num_output)
{
  // 타일링을 활용하여 Matrix ⨯ Vector 를 계산해보자!
  //
  // num_input, num_output 은 입력으로 주어지는 전체 데이터의 크기
  //              행 갯수    ⨯ 열 갯수
  //     Matrix:  num_output ⨯ num_input
  //     Vector:  num_input  ⨯ 1
  //     Result:  num_output ⨯ 1
  //
  // m_size_, v_size_ 는 입력을 타일링할 때 블록의 크기
  //                    행 갯수 ⨯ 열 갯수
  //     Matrix Block:  m_size_ ⨯ v_size_
  //     Vector Block:  v_size_ ⨯ 1
  //     Result:        m_size_ ⨯ 1

  // vec: float[v_size_]
  //
  // BRAM 상의 메모리 버퍼.
  float* const vec = this->vector();

  // mat: float[m_size_ * v_size_]
  //
  // BRAM 상의 메모리 버퍼. i행 j열 데이터는 mat[v_size_*i + j] 에 위치해있음.
  float* const mat = this->matrix();

  // 0) Initialize output vector
  for(int i = 0; i < num_output; ++i)
  {
    output[i] = 0;
  }

  for(int i = 0; i < num_output; i += m_size_)
  {
    for(int j = 0; j < num_input; j += v_size_)
    {
      // 0) Initialize input vector
      int block_row = min(m_size_, num_output-i);
      int block_col = min(v_size_, num_input-j);

      // !) Assign a vector
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

      // 3) Call a function `block_call() to execute MV multiplication
      const float* ret = this->blockMV();

      // 4) Accumulate intermediate results
      for(int row = 0; row < block_row; ++row)
      {
        output[i + row] += ret[row];
      }
    }
  }
}
