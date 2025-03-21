#include "tf_dnn.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <cstring>
#include <vector>

using namespace std;

template <typename T>
T *vectorToArray(vector<vector<T>> const &v)
{
  T *rv = (T *)malloc((v.size() * v[0].size()) * sizeof(T));
  for (unsigned i = 0; i < v.size(); i++)
    memcpy(rv + v[i].size() * i, &(v[i][0]), v[i].size() * sizeof(T));
  return rv;
}

TFDNN::TFDNN(std::string model, FPGA *dev) : TFDNN(model, dev, false, 32, 32) { }

TFDNN::TFDNN(std::string model, FPGA *dev, bool quantized, int weight_bits, int act_bits) : CommonDNN(dev, quantized, weight_bits, act_bits)
{
  fstream fin(model.c_str(), ios::in | ios::binary);
  int num_layers;
  fin >> num_layers;

  // assumption 1: input data is provided by "data" blob and input size is 1 x 28 x 28
  // assumption 2: the first input blob of Softmaxloss layer is connected to final ouptut of network
  input_idx_ = regDataIdx("data", 1 * 28 * 28);

  for (int i = 0; i < num_layers; ++i)
  {
    string layer_name, layer_type, input, output;
    fin >> layer_name >> layer_type >> input >> output;

    if (layer_type.compare("slim.layers.fully_connected") == 0)
    {
      int in_idx = getDataIdx(input);
      int input_size = data_[in_idx].size();

      int output_size;
      fin >> output_size;
      int out_idx = regDataIdx(layer_name, output_size);

      float act_min, act_max;
      float weight_min, weight_max;
      if(quantized) fin >> act_min >> act_max >> weight_min >> weight_max;

      int8_t *raw_weights_ = new int8_t[output_size * input_size];
      memset(raw_weights_, 0, output_size * input_size);
      for (int onode = 0; onode < output_size; onode++) {
        for (int inode = 0; inode < input_size; inode++) {
          int x;
          fin >> x;
          raw_weights_[onode * input_size + inode] = x;
        }
      }

      const int8_t *weight = raw_weights_;
      const float *bias = nullptr;

      // append new op
      ops_.push_back(move(unique_ptr<Op>(new MatVecOp(dev_, weight, bias, input_size, output_size, quantized, act_bits, act_min, act_max, weight_bits, weight_min, weight_max))));
      op_pair_.push_back({in_idx, out_idx});
    }
    else if (layer_type.compare("slim.layers.conv2d") == 0)
    {
      int in_idx = getDataIdx(input);
      int input_size = data_[in_idx].size();

      int output_size;
      fin >> output_size;
      int out_idx = regDataIdx(layer_name, output_size);

      int input_channel, input_height, input_width;
      fin >> input_channel >> input_height >> input_width;
      int conv_channel, conv_height, conv_width;
      fin >> conv_channel >> conv_height >> conv_width;
      float act_min, act_max;
      float weight_min, weight_max;
      if(quantized) fin >> act_min >> act_max >> weight_min >> weight_max;

      vector<vector<vector<vector<int8_t>>>> raw_weights_(conv_channel, vector<vector<vector<int8_t>>>(input_channel, vector<vector<int8_t>>(conv_height, vector<int8_t>(conv_width))));
      for (int ic = 0; ic < conv_channel; ic++) {
        for (int ii = 0; ii < input_channel; ii++) {
          for (int ih = 0; ih < conv_height; ih++) {
            for (int iw = 0; iw < conv_width; iw++) {
              int x;
              fin >> x;
              raw_weights_[ic][ii][ih][iw] = x;
            }
          }
        }
      }

      // append new op
      ops_.push_back(move(unique_ptr<Op>(new ConvOp(dev_, raw_weights_, input_size, output_size,
                                                    input_channel, input_height, input_width,
                                                    conv_channel, conv_height, conv_width,
                                                    quantized,
                                                    act_bits, act_min, act_max,
                                                    weight_bits, weight_min, weight_max))));
      op_pair_.push_back({in_idx, out_idx});
    }
    else if (layer_type.compare("tf.nn.relu") == 0)
    {
      int in_idx = getDataIdx(input);
      int input_size = data_[in_idx].size();

      int output_size = input_size;
      int out_idx = regDataIdx(layer_name, output_size);

      ops_.push_back(move(unique_ptr<Op>(new ReLUOp(input_size))));
      op_pair_.push_back({in_idx, out_idx});
    }
    else if (layer_type.compare("tf.nn.softmax") == 0)
    {
      int in_idx = getDataIdx(input);
      int input_size = data_[in_idx].size();

      int output_size = input_size;
      int out_idx = regDataIdx(layer_name, output_size);

      ops_.push_back(move(unique_ptr<Op>(new SoftmaxOp(input_size))));
      op_pair_.push_back({in_idx, out_idx});

      output_idx_ = out_idx;
    }
    else if (layer_type.compare("slim.layers.flatten") == 0)
    {
      int in_idx = getDataIdx(input);
      int input_size = data_[in_idx].size();

      int output_size = input_size;
      int out_idx = regDataIdx(layer_name, output_size);

      ops_.push_back(move(unique_ptr<Op>(new FlattenOp(input_size))));
      op_pair_.push_back({in_idx, out_idx});
    }
  }
}
