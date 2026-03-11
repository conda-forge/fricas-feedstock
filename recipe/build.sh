#!/bin/bash

set -ex

# SBCL-generated executables reference libzstd via @rpath; ensure it's findable
# export DYLD_FALLBACK_LIBRARY_PATH="$PREFIX/lib${DYLD_FALLBACK_LIBRARY_PATH:+:$DYLD_FALLBACK_LIBRARY_PATH}"
# export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

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

  FRICAS_TARGET="$PREFIX/lib/fricas/target/x86_64-w64-mingw32"

  # Copy FRICASsys.exe to fricas.exe so it can be invoked directly
  # (using a .bat wrapper is problematic because batch scripts require
  # "call fricas" instead of just "fricas").
  cp "$FRICAS_TARGET/bin/FRICASsys.exe" "$PREFIX/bin/fricas.exe"

  # Create activation scripts that set the FRICAS environment variable.
  # Use the root prefix (without /Library) since conda looks for
  # activation scripts at $CONDA_PREFIX/etc/conda/activate.d/.
  ACTIVATE_DIR="${PREFIX%/Library}/etc/conda/activate.d"
  DEACTIVATE_DIR="${PREFIX%/Library}/etc/conda/deactivate.d"
  mkdir -p "$ACTIVATE_DIR" "$DEACTIVATE_DIR"

  cat > "$ACTIVATE_DIR/fricas-activate.bat" << 'EOF'
@echo off
set "FRICAS=%CONDA_PREFIX%\Library\lib\fricas\target\x86_64-w64-mingw32"
EOF

  cat > "$ACTIVATE_DIR/fricas-activate.ps1" << 'EOF'
$env:FRICAS = "$env:CONDA_PREFIX\Library\lib\fricas\target\x86_64-w64-mingw32"
EOF

  cat > "$DEACTIVATE_DIR/fricas-deactivate.bat" << 'EOF'
@echo off
set "FRICAS="
EOF

  cat > "$DEACTIVATE_DIR/fricas-deactivate.ps1" << 'EOF'
Remove-Item Env:\FRICAS -ErrorAction SilentlyContinue
EOF
else
  # On Unix, use --enable-lisp-core to avoid macOS codesign issues.
  ./configure --prefix="$PREFIX" --with-lisp=sbcl --enable-lisp-core
  make
  make install
fi
