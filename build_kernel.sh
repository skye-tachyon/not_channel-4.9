#!/bin/bash

export PATH=$(pwd)/toolchain/clang/host/linux-x86/clang-r522817/bin:$PATH
export CROSS_COMPILE=$(pwd)/toolchain/clang/host/linux-x86/clang-r522817/bin/aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=$(pwd)/toolchain/clang/host/linux-x86/clang-r522817/bin/arm-linux-gnu-
export CC=$(pwd)/toolchain/clang/host/linux-x86/clang-r522817/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CLANG_TRIPLE_ARM32=arm-linux-gnu-
export ARCH=arm64
export TARGET_BUILD_VARIANT=user

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y LLVM=1 LLVM_IAS=1 river_defconfig
make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y LLVM=1 LLVM_IAS=1 -j16

cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image
