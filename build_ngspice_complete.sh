#!/bin/bash
# Complete self-contained build script for ngspice for Pyodide 0.27.7
# This script sets up all prerequisites and builds the wheel package

set -e

# Configuration
WORK_DIR=${WORK_DIR:-/tmp/ngspice-pyodide-build}
PYODIDE_VERSION="0.27.7"
EMSCRIPTEN_VERSION="3.1.58"
LIBTOOL_VERSION="2.5.4"
NGSPICE_VERSION="44.2"

echo "======================================================"
echo "Building ngspice $NGSPICE_VERSION for Pyodide $PYODIDE_VERSION"
echo "Working directory: $WORK_DIR"
echo "======================================================"

# Clean and create work directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# ============================================================================
# Step 1: Install libtool 2.5.4 (required for wasm32-emscripten support)
# ============================================================================
echo ""
echo "[1/6] Installing libtool $LIBTOOL_VERSION..."
if ! libtool --version 2>/dev/null | grep -q "$LIBTOOL_VERSION"; then
    wget -q https://ftp.gnu.org/gnu/libtool/libtool-$LIBTOOL_VERSION.tar.gz
    tar -xzf libtool-$LIBTOOL_VERSION.tar.gz
    cd libtool-$LIBTOOL_VERSION
    ./configure --prefix=/usr/local > /dev/null
    make -j$(nproc) > /dev/null
    sudo make install > /dev/null
    cd "$WORK_DIR"
    echo "✓ libtool $LIBTOOL_VERSION installed"
else
    echo "✓ libtool $LIBTOOL_VERSION already installed"
fi

# ============================================================================
# Step 2: Clone Pyodide and install Emscripten
# ============================================================================
echo ""
echo "[2/6] Setting up Pyodide $PYODIDE_VERSION..."
if [ ! -d "pyodide" ]; then
    git clone --depth 1 --branch $PYODIDE_VERSION https://github.com/pyodide/pyodide.git
    echo "✓ Pyodide cloned"
else
    echo "✓ Pyodide already cloned"
fi

cd pyodide

echo ""
echo "[3/6] Installing Emscripten $EMSCRIPTEN_VERSION..."
if [ ! -d "emsdk" ]; then
    git clone https://github.com/emscripten-core/emsdk.git
    cd emsdk
    ./emsdk install $EMSCRIPTEN_VERSION > /dev/null 2>&1
    ./emsdk activate $EMSCRIPTEN_VERSION > /dev/null 2>&1
    cd ..
    echo "✓ Emscripten installed"
else
    echo "✓ Emscripten already installed"
fi

# ============================================================================
# Step 3: Apply ngspice patches
# ============================================================================
echo ""
echo "[4/6] Applying ngspice package patches..."
if [ ! -d "packages/ngspice" ]; then
    # Download and apply the PR that adds ngspice support
    wget -q -O ngspice.patch https://patch-diff.githubusercontent.com/raw/pyodide/pyodide/pull/5601.patch

    # Apply patch (may have some rejects for changelog, but ngspice package should apply cleanly)
    git apply --reject --whitespace=fix ngspice.patch 2>/dev/null || true

    if [ -d "packages/ngspice" ]; then
        echo "✓ ngspice package patches applied"
    else
        echo "✗ Failed to apply ngspice patches"
        exit 1
    fi
else
    echo "✓ ngspice package already exists"
fi

# ============================================================================
# Step 4: Build ngspice following meta.yaml recipe
# ============================================================================
echo ""
echo "[5/6] Building ngspice..."

# Source Emscripten environment
source emsdk/emsdk_env.sh 2>/dev/null

# Set up build environment based on Pyodide conventions
export PATH="/usr/local/bin:$PATH"
export PYODIDE_ROOT="$WORK_DIR/pyodide"
export WASM_LIBRARY_DIR="$WORK_DIR/install"
export DISTDIR="$WORK_DIR/dist"
export PYODIDE_JOBS=${PYODIDE_JOBS:-$(nproc)}

# Pyodide's SIDE_MODULE flags for Emscripten (from build system)
export SIDE_MODULE_CFLAGS="-O2 -g0 -fPIC"
export SIDE_MODULE_LDFLAGS="-O2 -g0 -s WASM_BIGINT -s SIDE_MODULE=1"

mkdir -p "$WASM_LIBRARY_DIR" "$DISTDIR"

# Navigate to ngspice package and follow the meta.yaml build recipe
cd packages/ngspice

# Download ngspice source
if [ ! -d "ngspice-sf-mirror-ngspice-$NGSPICE_VERSION" ]; then
    echo "  Downloading ngspice source..."
    wget -q https://github.com/danchitnis/ngspice-sf-mirror/archive/refs/tags/ngspice-$NGSPICE_VERSION.zip
    unzip -q ngspice-$NGSPICE_VERSION.zip
fi

cd ngspice-sf-mirror-ngspice-$NGSPICE_VERSION

# Apply patches from meta.yaml
echo "  Applying ngspice source patches..."
patch -p1 < ../patches/0001-keep-alive-API-functions.patch > /dev/null 2>&1 || true
patch -p1 < ../patches/0001-no-hicum2.patch > /dev/null 2>&1 || true

# Build following meta.yaml recipe exactly
echo "  Running autogen..."
bash ./autogen.sh > /dev/null 2>&1

# Configure arguments from meta.yaml
configure_args=(
  --prefix="${WASM_LIBRARY_DIR}"
  --disable-xspice
  --disable-debug
  --disable-dependency-tracking
  --enable-cider
  --with-readline=no
  --disable-openmp
  --with-ngshared
  --host=wasm32-unknown-emscripten
)

echo "  Configuring..."
mkdir -p release-lib
cd release-lib
emconfigure ../configure "${configure_args[@]}" CFLAGS="${SIDE_MODULE_CFLAGS}" > /dev/null 2>&1

echo "  Compiling (this takes ~5 minutes)..."
emmake make -j ${PYODIDE_JOBS} LDFLAGS="${SIDE_MODULE_LDFLAGS}" > /dev/null 2>&1

echo "  Installing..."
emmake make install > /dev/null 2>&1

# Copy to dist directory as specified in meta.yaml
cp "${WASM_LIBRARY_DIR}/lib/libngspice.so" "${DISTDIR}/"

echo "✓ ngspice built successfully"

# ============================================================================
# Step 5: Create Python wheel package
# ============================================================================
echo ""
echo "[6/6] Creating Python wheel package..."

WHEEL_DIR="$WORK_DIR/wheel"
rm -rf "$WHEEL_DIR"
mkdir -p "$WHEEL_DIR/libngspice.libs"
mkdir -p "$WHEEL_DIR/libngspice-$NGSPICE_VERSION.dist-info"

# Copy the built library
cp "$DISTDIR/libngspice.so" "$WHEEL_DIR/libngspice.libs/"

# Create wheel metadata files
cat > "$WHEEL_DIR/libngspice-$NGSPICE_VERSION.dist-info/METADATA" <<EOF
Metadata-Version: 2.1
Name: libngspice
Version: $NGSPICE_VERSION
Summary: Ngspice shared library for Pyodide
Home-page: http://ngspice.sourceforge.net
License: BSD-3-Clause
Platform: pyodide_2024_0_wasm32
Classifier: Development Status :: 4 - Beta
Classifier: Intended Audience :: Developers
Classifier: License :: OSI Approved :: BSD License
Classifier: Programming Language :: Python :: 3
Classifier: Topic :: Scientific/Engineering :: Electronic Design Automation (EDA)
EOF

cat > "$WHEEL_DIR/libngspice-$NGSPICE_VERSION.dist-info/WHEEL" <<EOF
Wheel-Version: 1.0
Generator: build_ngspice_complete.sh
Root-Is-Purelib: false
Tag: cp312-cp312-pyodide_2024_0_wasm32
EOF

echo "libngspice" > "$WHEEL_DIR/libngspice-$NGSPICE_VERSION.dist-info/top_level.txt"

cat > "$WHEEL_DIR/libngspice-$NGSPICE_VERSION.dist-info/RECORD" <<EOF
libngspice.libs/libngspice.so,,
libngspice-$NGSPICE_VERSION.dist-info/METADATA,,
libngspice-$NGSPICE_VERSION.dist-info/WHEEL,,
libngspice-$NGSPICE_VERSION.dist-info/top_level.txt,,
libngspice-$NGSPICE_VERSION.dist-info/RECORD,,
EOF

# Create the wheel
cd "$WHEEL_DIR"
WHEEL_NAME="libngspice-$NGSPICE_VERSION-cp312-cp312-pyodide_2024_0_wasm32.whl"
python3 -m zipfile -c "$DISTDIR/$WHEEL_NAME" \
  libngspice.libs/libngspice.so \
  "libngspice-$NGSPICE_VERSION.dist-info/METADATA" \
  "libngspice-$NGSPICE_VERSION.dist-info/WHEEL" \
  "libngspice-$NGSPICE_VERSION.dist-info/top_level.txt" \
  "libngspice-$NGSPICE_VERSION.dist-info/RECORD" \
  2>/dev/null

echo "✓ Wheel created"

# ============================================================================
# Build complete!
# ============================================================================
echo ""
echo "======================================================"
echo "✓ Build completed successfully!"
echo "======================================================"
echo ""
echo "Output files:"
echo "  WebAssembly: $DISTDIR/libngspice.so"
SO_SIZE=$(ls -lh "$DISTDIR/libngspice.so" | awk '{print $5}')
echo "               Size: $SO_SIZE"
echo ""
echo "  Wheel:       $DISTDIR/$WHEEL_NAME"
WHEEL_SIZE=$(ls -lh "$DISTDIR/$WHEEL_NAME" | awk '{print $5}')
echo "               Size: $WHEEL_SIZE"
echo ""
echo "======================================================"
echo "Usage in Marimo:"
echo "======================================================"
echo ""
echo "1. Host the wheel:"
echo "   python3 -m http.server 8000 --directory $DISTDIR"
echo ""
echo "2. In your Marimo notebook:"
echo "   import micropip"
echo "   await micropip.install('http://localhost:8000/$WHEEL_NAME')"
echo "   await micropip.install('inspice')"
echo ""
echo "3. Use it:"
echo "   from InSpice.Spice.Netlist import Circuit"
echo "   circuit = Circuit('Test')"
echo "   # ... build your circuit ..."
echo ""
echo "See USING_NGSPICE_IN_MARIMO.md for detailed examples."
echo "======================================================"
