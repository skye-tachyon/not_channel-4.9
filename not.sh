#!/bin/bash
LLVM_PATH="/home/skye/bomb/clang/bin/"
TC_PATH="/home/skye/bomb/clang/bin/"
GCC_PATH="/usr/bin/"
LLD_PATH="/usr/bin/"
KERNEL_NAME="not_kernel-"
MAKE="./makeparallel"
BUILD_ENV="ARCH=arm64 CC=${TC_PATH}clang-21 CROSS_COMPILE=${TC_PATH}aarch64-linux-gnu-
CROSS_COMPILE_ARM32=${TC_PATH}arm-linux-gnueabi- LLVM=1 LLVM_IAS=1 PATH=$LLVM_PATH:$LLD_PATH:$PATH"  
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

rm -rf /home/skye/bomb/out/arch/arm64/boot/Image
rm -rf /home/skye/bomb/AnyKernel3/dtb
rm -rf /home/skye/bomb/dtbo.img
rm -rf .version
rm -rf .local
#make O=/home/skye/bomb/out clean
make O=/home/skye/bomb/out $BUILD_ENV channel_defconfig


echo "*****************************************"
make -j12 O=/home/skye/bomb/out $KERNEL_MAKE_ENV $BUILD_ENV Image.gz-dtb
IMAGE="/home/skye/bomb/out/arch/arm64/boot/Image.gz-dtb"
cp $IMAGE /home/skye/bomb/AnyKernel3/channel/Image.gz-dtb
echo "*****************************************"
cp /home/skye/bomb/out/arch/arm64/boot/dts/qcom/*.dtbo .
python3 $(pwd)/scripts/mkdtboimg.py create dtbo.img sdm632-channel-evt-overlay.dtbo sdm632-channel-dvt2-overlay.dtbo sdm632-channel-pvt-overlay.dtbo sdm632-channel-pvta-overlay.dtbo sdm632-channel-pvtb-overlay.dtbo sdm632-channel-pvtc-overlay.dtbo sdm632-channel-na-evt-overlay.dtbo sdm632-channel-na-dvt1b-overlay.dtbo sdm632-channel-tmo-dvt-overlay.dtbo
echo "*****************************************"
echo "***********DTBODTBODBTODTBO**************"
cp ./dtbo.img /home/skye/bomb/AnyKernel3/channel/dtbo.img
rm -rf ./dtbo.img
rm -rf ./*.dtbo

echo "**Build outputs**"
ls /home/skye/bomb/out/arch/arm64/boot
echo "**Build outputs**"

cd /home/skye/bomb/AnyKernel3/channel
rm *.zip
zip -r9 ${KERNEL_NAME}$(date +"%Y%m%d")+channel.zip .
echo "The bomb has been planted."

