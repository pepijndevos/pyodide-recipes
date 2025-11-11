#!/bin/bash
# Build ngspice wheel using Docker (mirrors pyodide-recipes CI)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/dist"

echo "======================================================"
echo "Building ngspice using Docker (pyodide-recipes CI method)"
echo "======================================================"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    echo "Install from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build Docker image
echo "[1/2] Building Docker image (this may take 10-15 minutes)..."
docker build -t pyodide-recipes-builder "$SCRIPT_DIR"

echo ""
echo "[2/2] Running build..."
docker run --rm -v "$OUTPUT_DIR:/output" pyodide-recipes-builder

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
