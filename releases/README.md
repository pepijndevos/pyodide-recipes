# ngspice Wheel for Pyodide 0.27.7 (Marimo)

This directory contains pre-built wheel packages of ngspice for Pyodide 0.27.7, compatible with [Marimo](https://marimo.io/).

## Quick Start

### Installation in Marimo

```python
import micropip

# Install from GitHub (replace with actual URL after pushing)
await micropip.install('https://github.com/YOUR-USERNAME/pyodide-recipes/raw/BRANCH-NAME/releases/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')

# Install InSpice (Python interface to ngspice)
await micropip.install('inspice')

# Use it!
from InSpice.Spice.Netlist import Circuit

circuit = Circuit('Voltage Divider')
circuit.V('input', 1, circuit.gnd, 10)
circuit.R(1, 1, 2, '1k')
circuit.R(2, 2, circuit.gnd, '1k')

simulator = circuit.simulator()
analysis = simulator.operating_point()
print(f"Output: {float(analysis['2'])}V")  # 5V
```

### Local Development

For local testing, host the wheel file:

```bash
# In the repository root
python3 -m http.server 8000 --directory releases

# Then in Marimo
await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')
```

## What's Inside

The wheel contains:
- `libngspice.so` - WebAssembly shared library (5.6M uncompressed, 1.8M in wheel)
- Compiled for Pyodide 0.27.7 / Emscripten 3.1.58
- Built with libtool 2.5.4 (wasm32-emscripten support)
- ngspice version 44.2

## Building from Source

To rebuild the wheel yourself, use the self-contained build script:

```bash
# From repository root
./build_ngspice_complete.sh

# The script will:
# 1. Install libtool 2.5.4
# 2. Clone Pyodide 0.27.7
# 3. Install Emscripten 3.1.58
# 4. Apply ngspice patches
# 5. Build ngspice following meta.yaml recipe
# 6. Create the wheel package

# Output will be in /tmp/ngspice-pyodide-build/dist/
```

## Documentation

- **[USING_NGSPICE_IN_MARIMO.md](../USING_NGSPICE_IN_MARIMO.md)** - Complete usage guide
- **[examples/marimo_ngspice_example.py](../examples/marimo_ngspice_example.py)** - Example circuits
- **[SUCCESSFUL_BUILD_027.md](../SUCCESSFUL_BUILD_027.md)** - Build details

## Technical Details

- **Platform tag**: `pyodide_2024_0_wasm32`
- **Python version**: cp312 (Python 3.12)
- **ABI**: cp312
- **License**: BSD-3-Clause (ngspice), GPL-3.0-or-later (InSpice)

## Version History

### libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl
- ngspice version: 44.2
- Built for: Pyodide 0.27.7
- Emscripten: 3.1.58
- Build date: 2025-11-11
- Features: Circuit simulation with CIDER support, no XSPICE
