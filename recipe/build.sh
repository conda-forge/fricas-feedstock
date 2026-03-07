#!/bin/bash

set -ex

./configure --prefix="$PREFIX" --with-lisp=sbcl --enable-lisp-core
make
make install
