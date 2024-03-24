#!/bin/bash

set -eu

if [ $# -lt 1 ]
then
  echo "usage:   $0 path_to_build_binary"
  echo "example: $0 ../../build/bin"
  exit 1
fi

set -x

SPLIT=$1/gguf-split
MAIN=$1/main
WORK_PATH=/tmp
CUR_DIR=$(pwd)

# 1. Get a model
(
  cd $WORK_PATH
  "$CUR_DIR"/../../scripts/hf.sh --repo ggml-org/models --file tinyllamas/stories15M.gguf
)
echo PASS

# 2. Split with max tensors strategy
$SPLIT --split-max-tensors 28  $WORK_PATH/stories15M.gguf $WORK_PATH/ggml-model-split
echo PASS
echo

# 2b. Test the sharded model is loading properly
$MAIN --model $WORK_PATH/ggml-model-split-00001-of-00003.gguf --random-prompt --n-predict 32
echo PASS
echo

# 3. Merge
$SPLIT --merge $WORK_PATH/ggml-model-split-00001-of-00003.gguf $WORK_PATH/ggml-model-merge.gguf
echo PASS
echo

# 3b. Test the merged model is loading properly
$MAIN --model $WORK_PATH/ggml-model-merge.gguf --random-prompt --n-predict 32
echo PASS
echo

# 4. Split with no tensor in metadata
$SPLIT --split-max-tensors 32 --no-tensor-in-metadata $WORK_PATH/ggml-model-merge.gguf $WORK_PATH/ggml-model-split-32-tensors
echo PASS
echo

# 4b. Test the sharded model is loading properly
$MAIN --model $WORK_PATH/ggml-model-split-32-tensors-00001-of-00003.gguf --random-prompt --n-predict 32
echo PASS
echo

# 5. Merge
$SPLIT --merge $WORK_PATH/ggml-model-split-32-tensors-00001-of-00003.gguf $WORK_PATH/ggml-model-merge-2.gguf
echo PASS
echo

# 5b. Test the merged model is loading properly
$MAIN --model $WORK_PATH/ggml-model-merge-2.gguf --random-prompt --n-predict 32
echo PASS
echo

# 6. Split with size strategy and no tensor in metadata
$SPLIT --split-max-size 40M $WORK_PATH/ggml-model-merge-2.gguf $WORK_PATH/ggml-model-split-40M
echo PASS
echo

# 6b. Test the sharded model is loading properly
$MAIN --model $WORK_PATH/ggml-model-split-40M-00001-of-00003.gguf --random-prompt --n-predict 32
echo PASS
echo
