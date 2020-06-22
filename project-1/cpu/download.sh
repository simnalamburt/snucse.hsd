#!/bin/bash
set -euo pipefail; IFS=$'\n\t'

if hash wget; then
  wget 'http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz' -cO data/t10k-images.idx3-ubyte.gz
  wget 'http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz' -cO data/t10k-labels.idx1-ubyte.gz
elif hash curl; then
  curl 'http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz' -LC- -o data/t10k-images.idx3-ubyte.gz
  curl 'http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz' -LC- -o data/t10k-labels.idx1-ubyte.gz
else
  echo 'curl or wget is required'
  exit 1
fi

sha256sum -c <<< "\
8d422c7b0a1c1c79245a5bcf07fe86e33eeafee792b84584aec276f5a2dbc4e6  data/t10k-images.idx3-ubyte.gz
f7ae60f92e00ec6debd23a6088c31dbd2371eca3ffa0defaefb259924204aec6  data/t10k-labels.idx1-ubyte.gz"

gzip -dkf data/{t10k-images.idx3-ubyte,t10k-labels.idx1-ubyte}.gz
xz -dkf pretrained_weights/cnn_weights.txt.xz pretrained_weights/quantized_cnn_weights.txt.xz
