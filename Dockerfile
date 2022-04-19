###############################
### Stage for building LLVM ###
###############################

FROM ubuntu:20.04 AS llvm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y git zip build-essential cmake ninja-build clang-11 && \
    apt-get clean

# Download the LLVM project source code.
RUN git clone --depth=1 --branch=llvmorg-14.0.1 https://github.com/llvm/llvm-project.git
WORKDIR llvm-project/build

# Run the ninja build.
RUN cmake -G Ninja \
    -DCLANG_VENDOR="Tizen" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64" \
    -DCMAKE_C_COMPILER=clang-11 \
    -DCMAKE_CXX_COMPILER=clang++-11 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/llvm \
    ../llvm
RUN ninja && ninja install

# Create symbolic links to binutils.
WORKDIR /llvm/bin
RUN for name in ar readelf nm strip; do \
      ln -s llvm-$name arm-linux-gnueabi-$name; \
      ln -s llvm-$name aarch64-linux-gnu-$name; \
      ln -s llvm-$name i686-linux-gnu-$name; \
    done


######################################
### Stage for constructing sysroot ###
######################################

FROM ubuntu:20.04 AS sysroot

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y python3 rpm2cpio cpio git && \
    apt-get clean

COPY sysroot/build-rootfs.py /sysroot/
COPY sysroot/*.patch /sysroot/

RUN /sysroot/build-rootfs.py --arch arm
RUN /sysroot/build-rootfs.py --arch arm64
RUN /sysroot/build-rootfs.py --arch x86

# Remove cached RPM packages.
RUN rm -r /sysroot/*/.rpms


###############################
### Produce a release image ###
###############################

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages for engine build.
RUN apt-get update && \
    apt-get install -y git curl ca-certificates python && \
    apt-get clean

# Copy build results from previous stages.
COPY --from=llvm /llvm/ /tizen_tools/toolchains/
COPY --from=sysroot /sysroot/ /tizen_tools/sysroot/
