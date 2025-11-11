#!/bin/bash
# Build script that runs inside Docker container

set -e

echo "======================================================"
echo "Building ngspice for Pyodide 0.27.7 using Docker"
echo "======================================================"

cd /build/pyodide

# Source Emscripten environment
source emsdk/emsdk_env.sh

# Verify packages/ngspice exists
if [ ! -d "packages/ngspice" ]; then
    echo "ERROR: packages/ngspice not found!"
    echo "The PR #5601 patch may not have applied correctly."
    exit 1
fi

echo ""
echo "Building libngspice package using pyodide build..."
echo ""

# Use pyodide build command (this is the proper way!)
cd packages/ngspice
pyodide build

echo ""
echo "======================================================"
echo "✓ Build completed successfully!"
echo "======================================================"

# List the built files
echo ""
echo "Built files in dist/:"
ls -lh dist/

# Copy to output directory if it exists
if [ -d "/output" ]; then
    echo ""
    echo "Copying outputs to /output..."
    cp -v dist/* /output/
    echo "✓ Files copied to /output"
fi

echo ""
echo "======================================================"
echo "Usage in Marimo:"
echo "======================================================"
echo ""
echo "import micropip"
echo "await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')"
echo "await micropip.install('inspice')"
echo "======================================================"
