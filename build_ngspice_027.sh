#!/bin/bash
set -e

# Source Emscripten 3.1.58
source /tmp/pyodide-027/emsdk/emsdk_env.sh

# Ensure libtool 2.5.4 is in PATH
export PATH="/usr/local/bin:$PATH"

# Set up Pyodide environment variables (based on Pyodide 0.27.7 build system)
export PYODIDE_ROOT=/tmp/pyodide-027
export WASM_LIBRARY_DIR=/tmp/ngspice-build/libs
export DISTDIR=/tmp/ngspice-build/dist
export PYODIDE_JOBS=4

# SIDE_MODULE flags for Emscripten (from Pyodide 0.27.7)
export SIDE_MODULE_CFLAGS="-O2 -g0 -fPIC"
export SIDE_MODULE_LDFLAGS="-O2 -g0 -s WASM_BIGINT -s SIDE_MODULE=1"

# Create output directories
mkdir -p $WASM_LIBRARY_DIR
mkdir -p $DISTDIR

# Navigate to ngspice package
cd /tmp/pyodide-027/packages/ngspice

# Download and extract source
echo "Downloading ngspice source..."
wget -q https://github.com/danchitnis/ngspice-sf-mirror/archive/refs/tags/ngspice-44.2.zip
unzip -q ngspice-44.2.zip
cd ngspice-sf-mirror-ngspice-44.2

# Apply patches
echo "Applying patches..."
patch -p1 < ../patches/0001-keep-alive-API-functions.patch
patch -p1 < ../patches/0001-no-hicum2.patch

# Run build script from meta.yaml
echo "Starting build..."
bash ./autogen.sh

configure_args=(
  --prefix=${WASM_LIBRARY_DIR}
  --disable-xspice
  --disable-debug
  --disable-dependency-tracking
  --enable-cider
  --with-readline=no
  --disable-openmp
  --with-ngshared
  --host=wasm32-unknown-emscripten
)

mkdir release-lib && cd release-lib
emconfigure ../configure "${configure_args[@]}" CFLAGS="${SIDE_MODULE_CFLAGS}"
emmake make -j ${PYODIDE_JOBS:-3} LDFLAGS="${SIDE_MODULE_LDFLAGS}"
emmake make install
cp ${WASM_LIBRARY_DIR}/lib/libngspice.so ${DISTDIR}/

echo "Build complete! Output in: $DISTDIR"
ls -lh $DISTDIR/
