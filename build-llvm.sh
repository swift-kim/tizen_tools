#!/bin/bash
# Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
OUTPUT_DIR="$SCRIPT_DIR/toolchains"
cd "$SCRIPT_DIR"

# Check out the LLVM project source code.
if [ -d llvm-project ]; then
  echo "The directory already exists. Skipping download."
else
  git clone --depth=1 --branch=llvmorg-14.0.1 https://github.com/llvm/llvm-project.git
fi
cd llvm-project

# Run the ninja build.
mkdir -p build && cd build
cmake -G Ninja \
  -DCLANG_VENDOR="Tizen" \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64" \
  -DCMAKE_C_COMPILER=clang-11 \
  -DCMAKE_CXX_COMPILER=clang++-11 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
  ../llvm
ninja
ninja install

# Create symbolic links to binutils.
# For details, see build/toolchain/custom/BUILD.gn in the buildroot.
cd "$OUTPUT_DIR/bin"
for name in ar readelf nm strip; do
  ln -sf llvm-$name arm-linux-gnueabi-$name
  ln -sf llvm-$name aarch64-linux-gnu-$name
  ln -sf llvm-$name i686-linux-gnu-$name
done
