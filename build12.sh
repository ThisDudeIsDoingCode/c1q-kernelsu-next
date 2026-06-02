#!/bin/bash

# 1. Get device codename from argument (default to c2q)
DEVICE=${1:-c2q}
echo "==> Building KernelSU Next for device: $DEVICE"

# 2. Copy the defconfig
cp -f kernelsu-defconfig/${DEVICE}_kor_singlew_defconfig arch/arm64/configs/vendor/${DEVICE}_kor_singlew_defconfig

# 3. Copy the patches
cp -rf kernelsu-patches/. .

# 4. Add KernelSU Next legacy branch
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s legacy

# 5. Build
export ARCH=arm64
mkdir -p out

BUILD_CROSS_COMPILE=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$(pwd)/toolchain/llvm-arm-toolchain-ship/10.0/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

make -j8 -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE vendor/${DEVICE}_kor_singlew_defconfig
make -j8 -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE

# 6. Build the anykernel flashable zip
cp out/arch/arm64/boot/Image $(pwd)/anykernel/

# Optional: Update AnyKernel display name dynamically
if [ "$DEVICE" == "c1q" ]; then
    sed -i 's/kernel.string=.*/kernel.string=Note20 KernelSU Next/' anykernel/anykernel.sh
else
    sed -i 's/kernel.string=.*/kernel.string=Note20 Ultra KernelSU Next/' anykernel/anykernel.sh
fi

cd anykernel && 7z a -tzip ../${DEVICE}_ksunext.zip . && cd ..

if [ -f "${DEVICE}_ksunext.zip" ]; then
 echo "==> Flashable zip file created at: $(pwd)/${DEVICE}_ksunext.zip"
else
 echo "==> Error: Zip file was not found!"
fi
