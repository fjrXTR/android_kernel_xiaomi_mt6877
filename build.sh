#!/bin/bash
#
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="villhaze!kernel-ruby-A13+-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$HOME/.cos/xrage"
AK3_DIR="$HOME/.cos/AnyKernel3"
DEFCONFIG="ruby_defconfig"

export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
echo "clang not found! Cloning to $TC_DIR..."
if ! git clone --depth=1 https://github.com/xyz-prjkt/xRageTC-clang -b main $TC_DIR; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export KBUILD_BUILD_USER=pajar
export KBUILD_BUILD_HOST=workstation

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j7 O=out ARCH=arm64 CC=clang LD=ld.lld CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz

if [ -f "out/arch/arm64/boot/Image.gz" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone https://github.com/fjrXTR/AnyKernel3 -b ruby; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
if ! [[ $HOSTNAME = "ubuntu" && $USER = "nobody" ]]; then
curl --upload-file $ZIPNAME http://oshi.at/$ZIPNAME; echo
fi
else
echo -e "\nCompilation failed!"
exit 1
fi