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
  # The Makefile install loop appends $(EXEEXT) (.exe) to each file it installs,
  # so it looks for FRICASsys.core.exe which doesn't exist. Copy manually.
  cp target/*/bin/FRICASsys.core "$PREFIX/lib/fricas/target/"*/bin/
  # The installed `fricas` is a bash script that cmd.exe cannot execute.
  # Create a .bat wrapper that sets FRICAS and invokes sbcl with the core
  # directly (equivalent to -nosman mode).
  cat > "$PREFIX/bin/fricas.bat" << 'EOF'
@echo off
set "FRICAS=%~dp0..\lib\fricas\target\x86_64-w64-mingw32"
sbcl --core "%FRICAS%\bin\FRICASsys.core" --end-runtime-options %*
EOF
else
  make install
fi
