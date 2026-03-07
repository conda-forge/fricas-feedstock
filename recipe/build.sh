#!/bin/bash

set -ex

# SBCL-generated executables reference libzstd via @rpath; ensure it's findable
export DYLD_FALLBACK_LIBRARY_PATH="$PREFIX/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [[ "$target_platform" == "win-64" ]]; then
  export PREFIX=${PREFIX}/Library
fi

./configure --prefix="$PREFIX" --with-lisp=sbcl --enable-lisp-core

if [[ "$target_platform" == "win-64" ]]; then
  # Skip contrib on Windows: the emacs contrib invokes FRICASsys (native SBCL)
  # which cannot resolve MSYS2-style paths (/d/bld/...) for its .core file.
  make all-src
  # command.list generation silently fails on Windows because interpsys (native
  # SBCL) can't resolve MSYS2 paths in ")read /d/bld/.../gen-cpl.lisp".
  # Create an empty one so make install succeeds.
  for d in target/*/lib; do
    [ -d "$d" ] && touch "$d/command.list"
  done
else
  make
fi

if [[ "$target_platform" == "win-64" ]]; then
  make install-src
else
  make install
fi
