#ifndef _FPGA_API_H_
#define _FPGA_API_H_
#include <sys/types.h>
#include <vector>
#include "compute.h"

// matrix vector multiplicator
// matrix M: M_SIZE by V_SIZE
// vector V: V_SIZE
// output = M * V

class FPGA
{

private:
  int fd_;
  float *data_;
  unsigned int *output_;
  int8_t *qvec_;
  int8_t *qmat_;
  int32_t *qout_;
  int8_t *qdata_;

  int m_size_;
  int v_size_;
  int data_size_;
  int num_block_call_;

public:
  FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size);
  ~FPGA();

  // return internal pointer for the data
  float *vector(void);
  int8_t *qmatrix(void);
  int8_t *qvector(void);
  void reset(void);
  int num_block_call(void);

  // perform matrix multiplication and return output array pointer
  const float *blockMV(Compute* comp);
  const int16_t *qblockMV(Compute* comp);

  // Input vector size: num_input
  // Matrix size: num_output * num_input
  // Output vector size: num_output
  // O = M * I
  void largeMV(const int8_t *mat, const float *input, float *output, int num_input, int num_output, Compute* comp);
  void convLowering(const std::vector<std::vector<std::vector<std::vector<int8_t>>>> &cnn_weights,
                    std::vector<std::vector<int8_t>> &new_weights,
                    const std::vector<std::vector<std::vector<float>>> &inputs,
                    std::vector<std::vector<float>> &new_inputs);
};
#endif
