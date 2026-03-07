#!/bin/bash

set -ex

# SBCL-generated executables reference libzstd via @rpath; ensure it's findable
export DYLD_FALLBACK_LIBRARY_PATH="$PREFIX/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

./configure --prefix="$PREFIX" --with-lisp=sbcl --enable-lisp-core
make
make install
