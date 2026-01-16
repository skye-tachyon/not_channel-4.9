#!/usr/bin/env bash
#
# Build script – not Kernel (channel) - Kanged script from Sanders-Revived Aurora kernel
# Moto G5s Plus
#

SECONDS=0

# ===== Device / Kernel =====
DEVICE="channel"
DEVICE_NAME="Moto G7 Play"
DEFCONFIG="channel_defconfig"

# ===== Toolchain =====
TC_DIR="$(pwd)/tc/clang-r522817"
export PATH="$TC_DIR/bin:$PATH"

# ===== AnyKernel3 =====
AK3_REPO="https://github.com/not-kernel/AnyKernel3"
AK3_BRANCH="channel"
AK3_DIR="$(pwd)/android/AnyKernel3"

# ===== Output =====
OUT_DIR="$(pwd)/out"
BOOT_DIR="$OUT_DIR/arch/arm64/boot"
KERNEL_IMG="$BOOT_DIR/Image.gz-dtb"

# ===== Zip =====
ZIPNAME="not-CI-$(date '+%Y%m%d-%H%M')-${DEVICE}"
if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
    ZIPNAME="${ZIPNAME}-$(echo "$head" | cut -c1-8)"
fi
ZIPNAME="${ZIPNAME}.zip"

# ===== Arguments =====
ARG=$1

if [[ "$ARG" == "-c" || "$ARG" == "--clean" ]]; then
    echo "[*] Cleaning output directory"
    rm -rf out
fi

if [[ "$ARG" == "-r" || "$ARG" == "--regen" ]]; then
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG savedefconfig
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
    echo "[+] Defconfig regenerated"
    exit 0
fi

if [[ "$ARG" == "-rf" || "$ARG" == "--regen-full" ]]; then
    mkdir -p out
    make O=out ARCH=arm64 $DEFCONFIG
    cp out/.config arch/arm64/configs/$DEFCONFIG
    echo "[+] Full defconfig regenerated"
    exit 0
fi

# ===== Toolchain check =====
if ! [ -d "$TC_DIR" ]; then
    echo "[*] Cloning AOSP clang..."
    git clone --depth=1 -b 18 \
        https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone \
        "$TC_DIR" || exit 1
fi

# ===== Build =====
mkdir -p out
echo "[*] Building $DEFCONFIG for $DEVICE_NAME"
make O=out ARCH=arm64 $DEFCONFIG

echo "[*] Starting compilation..."
make -j$(nproc --all) O=out ARCH=arm64 \
    CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CLANG_TRIPLE_ARM32=arm-linux-gnu- \
    TARGET_BUILD_VARIANT=user \
    CONFIG_SECTION_MISMATCH_WARN_ONLY=y \
    KCFLAGS=-w \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    DTC_EXT=$(pwd)/tools/dtc \
    LLVM=1 LLVM_IAS=1 Image.gz-dtb

# ===== Check compilation =====
if ! [ -f "$KERNEL_IMG" ]; then
    echo "[!] Compilation failed – Image.gz-dtb not found"
    exit 1
fi

echo "[+] Kernel compiled successfully"

# ===== Prepare AnyKernel3 =====
rm -rf AnyKernel3
echo "[*] Cloning AnyKernel3 for $DEVICE"
git clone -q -b "$AK3_BRANCH" "$AK3_REPO" AnyKernel3 || exit 1

# Copy the kernel image to AnyKernel3
cp "$KERNEL_IMG" AnyKernel3

cp out/arch/arm64/boot/dts/qcom/*.dtbo .


python3 $(pwd)/scripts/mkdtboimg.py create dtbo.img sdm632-channel-evt-overlay.dtbo sdm632-channel-dvt2-overlay.dtbo sdm632-channel-pvt-overlay.dtbo sdm632-channel-pvta-overlay.dtbo sdm632-channel-pvtb-overlay.dtbo sdm632-channel-pvtc-overlay.dtbo sdm632-channel-na-evt-overlay.dtbo sdm632-channel-na-dvt1b-overlay.dtbo sdm632-channel-tmo-dvt-overlay.dtbo
echo "***********DTBODTBODBTODTBO**************"

cp ./dtbo.img AnyKernel3/dtbo.img

rm -rf ./dtbo.img
rm -rf ./*.dtbo

# Remove boot output folder (Supra style)
rm -rf out/arch/arm64/boot

# ===== Zip =====
cd AnyKernel3 || exit 1
zip -r9 "../$ZIPNAME" * -x .git README.md "*placeholder*"
cd ..
rm -rf AnyKernel3

echo
echo "[✓] Done in $((SECONDS / 60))m $((SECONDS % 60))s"
echo "[✓] Zip: $ZIPNAME"
