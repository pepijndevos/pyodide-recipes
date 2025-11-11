# Using ngspice in Marimo with Pyodide

This guide explains how to use the ngspice circuit simulator in Marimo notebooks.

## Quick Start - Pre-built Wheel

Install the pre-built wheel directly from this repository:

```python
import micropip

# Install libngspice from GitHub
REPO = "https://github.com/pepijndevos/pyodide-recipes"
BRANCH = "claude/check-pyodide-ngspice-build-011CV1tZ6hoEg5itwAYbFAiJ"
await micropip.install(f'{REPO}/raw/{BRANCH}/releases/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')

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
print(f"Output: {float(analysis['2'])}V")  # Should be 5V
```

## Building from Source

If you want to rebuild the wheel yourself:

### Option 1: Docker (Recommended)
```bash
./build-with-docker.sh
```

Mirrors the pyodide-recipes CI workflow. Uses `pyodide build-recipes` command.

### Option 2: Conda/Mamba
```bash
./build-with-conda.sh
```

Uses conda to set up the environment, then runs `pyodide build-recipes`.

**Requirements:**
- Docker (Option 1) or Conda/Mamba (Option 2)
- 10-15 minutes build time
- Outputs wheel to `dist/`

## How It Works

1. **libngspice** is a shared library (WebAssembly .so file) built for Pyodide
2. **InSpice** (pure Python package) uses CFFI to load libngspice dynamically
3. **InSpice has Pyodide support** - automatically detects web environment
4. The wheel packages the .so file in `libngspice.libs/` directory

## Example Circuits

See [examples/marimo_ngspice_example.py](examples/marimo_ngspice_example.py) for:
- Voltage divider
- RC transient analysis
- AC frequency response (Bode plots)
- Diode I-V characteristics

## Technical Details

- **ngspice version:** 44.2
- **Pyodide version:** 0.27.7  
- **Emscripten version:** 3.1.58
- **Wheel platform:** `pyodide_2024_0_wasm32`
- **WebAssembly module:** 5.6M uncompressed, 1.8M in wheel

### Wheel Structure

```
libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl
├── libngspice.libs/
│   └── libngspice.so          # WebAssembly shared library
└── libngspice-44.2.dist-info/
    ├── METADATA
    ├── WHEEL
    ├── top_level.txt
    └── RECORD
```

## Troubleshooting

### Library Not Found

If InSpice can't find the library:

```python
import os
os.environ['NGSPICE_LIBRARY_PATH'] = '/lib/python3.12/site-packages/libngspice.libs/libngspice.so'

from InSpice.Spice.Netlist import Circuit
```

### Enable Debug Logging

```python
import logging
logging.basicConfig(level=logging.DEBUG)

from InSpice.Spice.NgSpice.Shared import NgSpiceShared
# This will show library loading details
```

## References

- [InSpice on PyPI](https://pypi.org/project/inspice/)
- [ngspice Documentation](http://ngspice.sourceforge.net/docs.html)
- [Marimo Documentation](https://docs.marimo.io/)
- [Pyodide Documentation](https://pyodide.org/)

## License

- **ngspice**: BSD-3-Clause
- **InSpice**: GPL-3.0-or-later
