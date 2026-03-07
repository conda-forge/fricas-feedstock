#!/bin/bash

set -ex

# SBCL-generated executables reference libzstd via @rpath; ensure it's findable
export DYLD_FALLBACK_LIBRARY_PATH="$PREFIX/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [[ "$target_platform" == "win-64" ]]; then
  export PREFIX=${PREFIX}/Library
fi

if [[ "$target_platform" == "win-64" ]]; then
  # On Windows, build a standalone FRICASsys.exe (no --enable-lisp-core)
  # because SBCL can't resolve MSYS2-style paths for .core files.
  ./configure --prefix="$PREFIX" --with-lisp=sbcl
  # Skip contrib: the emacs contrib invokes FRICASsys which cannot resolve
  # MSYS2-style paths (/d/bld/...) for its .core file.
  make all-src
  # command.list generation silently fails on Windows because interpsys
  # can't resolve MSYS2 paths in ")read /d/bld/.../gen-cpl.lisp".
  for d in target/*/lib; do
    [ -d "$d" ] && touch "$d/command.list"
  done
  make install-src
  # The installed `fricas` is a bash script that cmd.exe cannot execute.
  # Create a .bat wrapper that invokes FRICASsys.exe directly.
  cat > "$PREFIX/bin/fricas.bat" << 'EOF'
@echo off
set "FRICAS=%~dp0..\lib\fricas\target\x86_64-w64-mingw32"
"%FRICAS%\bin\FRICASsys.exe" %*
EOF
else
  # On Unix, use --enable-lisp-core to avoid macOS codesign issues.
  ./configure --prefix="$PREFIX" --with-lisp=sbcl --enable-lisp-core
  make
  make install
fi
