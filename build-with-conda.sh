#!/bin/bash
# Build ngspice wheel using conda (mirrors pyodide-recipes CI)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/dist"

echo "======================================================"
echo "Building ngspice using conda (pyodide-recipes CI method)"
echo "======================================================"
echo ""

# Check if conda/mamba is available
if ! command -v conda &> /dev/null && ! command -v mamba &> /dev/null; then
    echo "ERROR: conda/mamba is not installed"
    echo "Install from: https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

# Activate conda base environment
eval "$(conda shell.bash hook)" 2>/dev/null || true

# Create/update conda environment
echo "[1/4] Setting up conda environment..."
if conda env list | grep -q "^pyodide-env "; then
    echo "  Updating existing pyodide-env environment"
    mamba env update -n pyodide-env -f environment.yml
else
    echo "  Creating pyodide-env environment"
    mamba env create -f environment.yml
fi

# Activate environment
conda activate pyodide-env

# Install pyodide-build
echo ""
echo "[2/4] Installing pyodide-build..."
python -m pip install ./pyodide-build/
pyodide xbuildenv install

# Install and patch emscripten
echo ""
echo "[3/4] Installing emscripten..."
python tools/install_and_patch_emscripten.py

# Build ngspice
echo ""
echo "[4/4] Building libngspice..."
source emsdk/emsdk_env.sh
mkdir -p repodata build-logs "$OUTPUT_DIR"

pyodide build-recipes libngspice --install --install-dir=./repodata --log-dir=build-logs

# Copy wheel to output
cp -v repodata/libngspice*.whl "$OUTPUT_DIR/"

echo ""
echo "======================================================"
echo "✓ Build complete!"
echo "======================================================"
echo ""
echo "Wheel created in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.whl

echo ""
echo "To test in Marimo:"
echo "  python3 -m http.server 8000 --directory dist"
echo ""
echo "Then in Marimo:"
echo "  import micropip"
echo "  await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')"
echo "  await micropip.install('inspice')"
echo ""
