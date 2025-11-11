#!/bin/bash
# Wrapper script to build ngspice using Docker
# This is the easiest way to get a reproducible build!

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/dist"

echo "======================================================"
echo "Building ngspice for Pyodide 0.27.7 using Docker"
echo "======================================================"
echo ""
echo "This will:"
echo "  1. Build a Docker image with Python 3.12"
echo "  2. Use pyodide build tools properly"
echo "  3. Output wheel to: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Build Docker image
echo "[Step 1/2] Building Docker image (this may take a few minutes on first run)..."
docker build -t pyodide-ngspice-builder "$SCRIPT_DIR"

echo ""
echo "[Step 2/2] Running build in Docker container..."
docker run --rm -v "$OUTPUT_DIR:/output" pyodide-ngspice-builder

echo ""
echo "======================================================"
echo "✓ Build complete!"
echo "======================================================"
echo ""
echo "Output files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"

echo ""
echo "To use in Marimo:"
echo "  1. Host the wheel:"
echo "     python3 -m http.server 8000 --directory dist"
echo ""
echo "  2. In Marimo notebook:"
echo "     import micropip"
echo "     await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')"
echo "     await micropip.install('inspice')"
echo ""
