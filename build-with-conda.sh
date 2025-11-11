#!/bin/bash
# Build ngspice for Pyodide 0.27.7 using conda for Python 3.12
# This properly uses pyodide build tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-/tmp/ngspice-pyodide-conda-build}"
OUTPUT_DIR="$SCRIPT_DIR/dist"

echo "======================================================"
echo "Building ngspice for Pyodide 0.27.7 using conda"
echo "======================================================"
echo ""

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "ERROR: conda is not installed"
    echo "Please install Miniconda or Anaconda from:"
    echo "  https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

# Create conda environment
echo "[1/5] Creating conda environment..."
if conda env list | grep -q "pyodide-ngspice-builder"; then
    echo "  Environment already exists, using existing one"
else
    conda env create -f "$SCRIPT_DIR/environment-py312.yml"
fi

# Activate environment
echo ""
echo "[2/5] Activating conda environment..."
eval "$(conda shell.bash hook)"
conda activate pyodide-ngspice-builder

# Verify Python version
PYTHON_VERSION=$(python --version | cut -d' ' -f2 | cut -d'.' -f1,2)
if [ "$PYTHON_VERSION" != "3.12" ]; then
    echo "ERROR: Expected Python 3.12, got $PYTHON_VERSION"
    exit 1
fi
echo "  ✓ Using Python $PYTHON_VERSION"

# Install libtool 2.5.4
echo ""
echo "[3/5] Installing libtool 2.5.4..."
if ! libtool --version 2>/dev/null | grep -q "2.5.4"; then
    cd /tmp
    wget -q https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.gz
    tar -xzf libtool-2.5.4.tar.gz
    cd libtool-2.5.4
    ./configure --prefix="$CONDA_PREFIX" > /dev/null
    make -j$(nproc) > /dev/null
    make install > /dev/null
    cd /tmp
    rm -rf libtool-2.5.4*
    echo "  ✓ libtool 2.5.4 installed"
else
    echo "  ✓ libtool 2.5.4 already installed"
fi

# Setup Pyodide
echo ""
echo "[4/5] Setting up Pyodide 0.27.7..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [ ! -d "pyodide" ]; then
    git clone --depth 1 --branch 0.27.7 https://github.com/pyodide/pyodide.git
    cd pyodide

    # Install Emscripten
    git clone https://github.com/emscripten-core/emsdk.git
    cd emsdk
    ./emsdk install 3.1.58 > /dev/null 2>&1
    ./emsdk activate 3.1.58 > /dev/null 2>&1
    cd ..

    # Apply ngspice patches
    wget -q -O /tmp/ngspice.patch https://patch-diff.githubusercontent.com/raw/pyodide/pyodide/pull/5601.patch
    git apply --reject --whitespace=fix /tmp/ngspice.patch 2>/dev/null || true
    rm /tmp/ngspice.patch

    echo "  ✓ Pyodide setup complete"
else
    cd pyodide
    echo "  ✓ Using existing Pyodide checkout"
fi

# Verify ngspice package exists
if [ ! -d "packages/ngspice" ]; then
    echo "ERROR: packages/ngspice not found!"
    echo "The PR #5601 patch may not have applied correctly."
    exit 1
fi

# Build ngspice using pyodide build
echo ""
echo "[5/5] Building ngspice using pyodide build..."
source emsdk/emsdk_env.sh 2>/dev/null

cd packages/ngspice

echo "  Running: pyodide build"
echo "  (This will take several minutes...)"
echo ""

pyodide build

echo ""
echo "======================================================"
echo "✓ Build completed successfully!"
echo "======================================================"

# Copy to output directory
mkdir -p "$OUTPUT_DIR"
cp -v dist/* "$OUTPUT_DIR/"

echo ""
echo "Output files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"

echo ""
echo "======================================================"
echo "Usage in Marimo:"
echo "======================================================"
echo ""
echo "  1. Host the wheel:"
echo "     python3 -m http.server 8000 --directory dist"
echo ""
echo "  2. In Marimo notebook:"
echo "     import micropip"
echo "     await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')"
echo "     await micropip.install('inspice')"
echo ""
echo "Conda environment: pyodide-ngspice-builder"
echo "To clean up: conda env remove -n pyodide-ngspice-builder"
echo "======================================================"
