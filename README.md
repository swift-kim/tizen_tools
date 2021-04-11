# tizen_tools

Tizen cross-compilation toolchain for building the Flutter engine.

## How to generate toolchains

You need a Linux x64 host with [Tizen Studio](https://developer.tizen.org/development/tizen-studio/download) 4.0 or later installed. It is assumed that `tizen-studio` is installed in the default location (_HOME_), and the required package (_NativeToolchain-Gcc-9.2_) is already installed. Run the following commands in this directory to copy required files from `tizen-studio` to `toolchains`. Typically, you have to run this only once.

```sh
TIZEN_STUDIO=$HOME/tizen-studio

mkdir -p toolchains
cp -r $TIZEN_STUDIO/tools/llvm-10/* toolchains
cd toolchains/bin

# For arm
for f in $TIZEN_STUDIO/tools/arm-linux-gnueabi-gcc-9.2/bin/arm-linux-*; do
  b=`basename $f`
  cp $f armv7l-tizen-${b:4:99}
done

# For arm64
for f in $TIZEN_STUDIO/tools/aarch64-linux-gnu-gcc-9.2/bin/aarch64-linux-*; do
  b=`basename $f`
  cp $f aarch64-tizen-${b:8:99}
done
ln -s aarch64-tizen-linux-gnu-ld ld # fix me!
cp -r $TIZEN_STUDIO/tools/aarch64-linux-gnu-gcc-9.2/lib/gcc/aarch64-tizen-linux-gnu/9.2.0/*.{o,a} \
  ../../sysroot/arm64/usr/lib # fix me!

# For x86
for f in $TIZEN_STUDIO/tools/i586-linux-gnueabi-gcc-9.2/bin/i586-linux-*; do
  b=`basename $f`
  cp $f i586-tizen-${b:5:99}
done
mkdir -p ../lib/gcc
cp -r $TIZEN_STUDIO/tools/i586-linux-gnueabi-gcc-9.2/lib/gcc/i586-tizen-linux-gnueabi ../lib/gcc
```

## How to generate sysroots

Run `build-rootfs.py` to generate sysroots for arm (device) and x86 (emulator).

```sh
# For Tizen 5.5+
sysroot/build-rootfs.py --arch arm
sysroot/build-rootfs.py --arch arm64
sysroot/build-rootfs.py --arch x86

# For Tizen 4.0 (optional)
sysroot/build-rootfs.py --arch arm \
--base-repo http://download.tizen.org/snapshots/tizen/4.0-base/latest/repos/arm/packages \
--unified-repo http://download.tizen.org/snapshots/tizen/4.0-unified/latest/repos/standard/packages \
--output arm_40
sysroot/build-rootfs.py --arch x86 \
--base-repo http://download.tizen.org/snapshots/tizen/4.0-base/latest/repos/emulator32/packages \
--unified-repo http://download.tizen.org/snapshots/tizen/4.0-unified/latest/repos/standard/packages \
--output x86_40
```

The sysroot should be re-generated if any dependencies are added by future updates (`git pull`).
