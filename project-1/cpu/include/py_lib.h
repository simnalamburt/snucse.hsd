#ifndef _PY_LIB_H_
#define _PY_LIB_H_

extern "C"
{
  void *getTFNet(void *network, int m_size, int v_size);
  void *getTFQuantizedNet(void *network, int m_size, int v_size, int w_bits, int a_bits);
  void delTFNet(void *net_ptr);
  void inferenceTF(void *net_ptr, const void *in, void *out, int *num_call);
}

#endif
