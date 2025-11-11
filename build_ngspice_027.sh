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

# Create wheel package for Marimo/Pyodide
echo ""
echo "Creating wheel package..."
WHEEL_DIR=/tmp/ngspice-wheel
rm -rf $WHEEL_DIR
mkdir -p $WHEEL_DIR/libngspice.libs
mkdir -p $WHEEL_DIR/libngspice-44.2.dist-info

# Copy .so file
cp $DISTDIR/libngspice.so $WHEEL_DIR/libngspice.libs/

# Create METADATA
cat > $WHEEL_DIR/libngspice-44.2.dist-info/METADATA <<'EOF'
Metadata-Version: 2.1
Name: libngspice
Version: 44.2
Summary: Ngspice shared library for Pyodide
Home-page: http://ngspice.sourceforge.net
License: BSD-3-Clause
Platform: pyodide_2024_0_wasm32
EOF

# Create WHEEL
cat > $WHEEL_DIR/libngspice-44.2.dist-info/WHEEL <<'EOF'
Wheel-Version: 1.0
Generator: build_ngspice_027.sh
Root-Is-Purelib: false
Tag: cp312-cp312-pyodide_2024_0_wasm32
EOF

# Create top_level.txt
echo "libngspice" > $WHEEL_DIR/libngspice-44.2.dist-info/top_level.txt

# Create RECORD
cat > $WHEEL_DIR/libngspice-44.2.dist-info/RECORD <<'EOF'
libngspice.libs/libngspice.so,,
libngspice-44.2.dist-info/METADATA,,
libngspice-44.2.dist-info/WHEEL,,
libngspice-44.2.dist-info/top_level.txt,,
libngspice-44.2.dist-info/RECORD,,
EOF

# Create wheel file
cd $WHEEL_DIR
python3 -m zipfile -c $DISTDIR/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl \
  libngspice.libs/libngspice.so \
  libngspice-44.2.dist-info/METADATA \
  libngspice-44.2.dist-info/WHEEL \
  libngspice-44.2.dist-info/top_level.txt \
  libngspice-44.2.dist-info/RECORD

echo ""
echo "✓ Wheel created successfully!"
ls -lh $DISTDIR/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl

echo ""
echo "==================== BUILD SUMMARY ===================="
echo "WebAssembly module: $DISTDIR/libngspice.so"
echo "Wheel package:      $DISTDIR/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl"
echo ""
echo "To use in Marimo:"
echo "  1. Host the wheel: python3 -m http.server 8000 --directory $DISTDIR"
echo "  2. In Marimo: await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')"
echo "  3. In Marimo: await micropip.install('inspice')"
echo "======================================================"
