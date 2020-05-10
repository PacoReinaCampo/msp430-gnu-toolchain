#!/usr/bin/env bash

# This directory contains the sources for gcc, newlib, binutils, and gdb used
# to build the "msp430-gcc" binary toolchain packages distributed by TI.
#
# The following example script demonstrates how these sources can be used to
# build a toolchain from these sources. It has been developed on a CentOS 7
# machine, and may need to be adapted for use on other platforms, such as
# Microsoft Windows. 
#
# Some tools and libraries are required to build the toolchain in this manner.
# On a CentOS 7 system these dependencies can be installed with the following
# command:
#
#   yum install "@Development Tools" texinfo ncurses-devel zlib-devel wget
#
# On a Ubuntu Xenial system, the following command will install the required
# pre-requisites. It is advisable to run "apt-get update" first.
#
#   apt-get install build-essential flex bison texinfo
#
# On macOS it is recommended to install the GNU coreutils package, in addition
# to the XCode Developer tools. The following homebrew command
# (https://brew.sh/) is a simple way to install coreutils:
#
#   brew install coreutils

set -e
set -x

configure_args_common='--target=msp430-elf --enable-languages=c,c++ --disable-nls --enable-initfini-array'
# Note: binutils doesn't build without warnings on macOS
# https://sourceware.org/ml/binutils/2013-12/msg00051.html
configure_args_binutils=$(echo --disable-{sim,gdb,werror})
configure_args_gcc=$(echo --enable-target-optspace --enable-newlib-nano-formatted-io)
configure_args_gdb=$(echo --disable-{binutils,gas,ld,gprof,etc} --without-{mpfr,lzma} --with-python=no)

pushd gcc
  # Download sources for gcc prerequisites (gmp, mpfr, mpc, and isl)
  (
    # download_prerequisites requires wget which isn't on macOS
    wget() {
      curl -O "$@"
    }
    source ./contrib/download_prerequisites
  )

  # Create a single source tree for gcc and newlib
  for dir in libgloss newlib; do
    ln -fns ../newlib/$dir $dir
  done
popd

# Create directories
rm -rf build install
mkdir -p build/{binutils,gcc,gdb} install

# Build binutils
pushd build/binutils
  ../../binutils/configure $configure_args_common $configure_args_binutils --with-pkgversion="${pkg_version-$USER}"
  make
  make install DESTDIR=$PWD/../../install
popd

# Build gcc and newlib
pushd build/gcc
  (
    export PATH=$PWD/../../install/usr/local/bin:$PATH
    ../../gcc/configure $configure_args_common $configure_args_gcc --with-pkgversion="${pkg_version-$USER}"
    make
    make install DESTDIR=$PWD/../../install
  )
popd

# Build gdb
pushd build/gdb
  ../../gdb/configure $configure_args_common $configure_args_gdb --with-pkgversion="${pkg_version-$USER}"
  make
  make install DESTDIR=$PWD/../../install
popd

echo "Build Complete [toolchain root directory: install/usr/local/bin]"
exit 0

# The dejagnu/ directory contains a copy of msp430-sim.exp, downloaded from:
# http://git.savannah.gnu.org/cgit/dejagnu.git/plain/baseboards/msp430-sim.exp
#
# To run the testsuites:
export DEJAGNU=$PWD/dejagnu/site.exp
pushd build/binutils
make -k check
popd
pushd build/gcc
make -k check
popd
pushd build/gdb
make -k check
popd
