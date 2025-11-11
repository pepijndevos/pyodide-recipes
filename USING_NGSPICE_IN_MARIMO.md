# Using ngspice in Marimo with Pyodide 0.27.7

This guide explains how to use the ngspice circuit simulator in Marimo notebooks through the InSpice Python interface.

## Overview

We've built `libngspice.so` (the ngspice shared library) as a WebAssembly module compatible with Pyodide 0.27.7 (used by Marimo). The library is packaged as a wheel that can be installed alongside the InSpice Python package.

## Package Files

- **Wheel**: `dist/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl` (1.8M)
  - Contains `libngspice.so` WebAssembly module
  - Compatible with Pyodide 0.27.7 / Emscripten 3.1.58
  - Built with libtool 2.5.4 for wasm32-emscripten support

- **Build Script**: `build_ngspice_027.sh`
  - Reproduces the build locally
  - See `SUCCESSFUL_BUILD_027.md` for details

## Installation in Marimo

### Option 1: Local File Server (Development)

1. **Start a local file server** from the repository root:
   ```bash
   python3 -m http.server 8000 --directory dist
   ```

2. **In your Marimo notebook**, run:
   ```python
   import micropip

   # Install libngspice from local server
   await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')

   # Install inspice from PyPI
   await micropip.install('inspice')
   ```

3. **Use ngspice via InSpice**:
   ```python
   from InSpice.Spice.Netlist import Circuit

   # Create a simple RC circuit
   circuit = Circuit('RC Circuit')
   circuit.V('input', 1, circuit.gnd, 10)
   circuit.R(1, 1, 2, '1k')
   circuit.C(1, 2, circuit.gnd, '1uF')

   # Run simulation
   simulator = circuit.simulator()
   analysis = simulator.transient(step_time='0.1ms', end_time='10ms')

   # Plot results
   import matplotlib.pyplot as plt
   plt.plot(analysis.time.as_ndarray(), analysis['2'].as_ndarray())
   plt.xlabel('Time (s)')
   plt.ylabel('Voltage (V)')
   plt.title('RC Circuit Response')
   plt.show()
   ```

### Option 2: Hosted Wheel (Production)

For production use, host the wheel file on a web server or CDN:

```python
import micropip

# Install from your hosted location
await micropip.install('https://your-domain.com/path/to/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')
await micropip.install('inspice')
```

### Option 3: GitHub Releases

If you publish a release on GitHub, you can install directly from there:

```python
import micropip

REPO_URL = "https://github.com/YOUR-USERNAME/pyodide-recipes"
RELEASE_TAG = "v1.0.0"
WHEEL_NAME = "libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl"

await micropip.install(f'{REPO_URL}/releases/download/{RELEASE_TAG}/{WHEEL_NAME}')
await micropip.install('inspice')
```

## How It Works

1. **InSpice** (fork of PySpice) is a pure Python package that provides a high-level interface to ngspice
2. **InSpice uses CFFI** to dynamically load `libngspice.so` at runtime via `ffi.dlopen()`
3. **InSpice has Pyodide support** - it checks for `ConfigInstall.OS.on_web` and looks for `libngspice{}.so`
4. **The wheel structure** places `libngspice.so` in `libngspice.libs/` directory, which is the standard location for shared libraries in Python wheels
5. **micropip.install()** extracts the wheel and makes the library available to InSpice

## Library Loading

InSpice finds the library through:
1. **Environment variable**: `NGSPICE_LIBRARY_PATH` (if set)
2. **ctypes.util.find_library()**: Searches standard locations including `site-packages/libngspice.libs/`
3. **Platform detection**: Automatically detects Pyodide environment

## Troubleshooting

### Library Not Found

If InSpice can't find the library, you can explicitly set the path:

```python
import os
os.environ['NGSPICE_LIBRARY_PATH'] = '/lib/python3.12/site-packages/libngspice.libs/libngspice.so'

from InSpice.Spice.Netlist import Circuit
# ... your code
```

### Check Installation

Verify the library is installed:

```python
import importlib.util
import os

# Check if inspice is installed
if importlib.util.find_spec('InSpice'):
    print("✓ InSpice installed")

# Check if libngspice.so exists
lib_path = '/lib/python3.12/site-packages/libngspice.libs/libngspice.so'
if os.path.exists(lib_path):
    print(f"✓ libngspice.so found at {lib_path}")
    import subprocess
    result = subprocess.run(['file', lib_path], capture_output=True, text=True)
    print(f"  {result.stdout.strip()}")
else:
    print(f"✗ libngspice.so not found at {lib_path}")
```

### Enable Debug Logging

```python
import logging
logging.basicConfig(level=logging.DEBUG)

from InSpice.Spice.NgSpice.Shared import NgSpiceShared
# This will show library loading details
```

## Example Circuits

### Voltage Divider

```python
from InSpice.Spice.Netlist import Circuit

circuit = Circuit('Voltage Divider')
circuit.V('input', 1, circuit.gnd, 10)
circuit.R(1, 1, 2, '1k')
circuit.R(2, 2, circuit.gnd, '1k')

simulator = circuit.simulator()
analysis = simulator.operating_point()

print(f"Output voltage: {float(analysis['2'])} V")
```

### RC Low-Pass Filter

```python
from InSpice.Spice.Netlist import Circuit
import numpy as np

circuit = Circuit('RC Low-Pass Filter')
circuit.V('input', 1, circuit.gnd, 'AC 1')
circuit.R(1, 1, 2, '1k')
circuit.C(1, 2, circuit.gnd, '100nF')

simulator = circuit.simulator()
analysis = simulator.ac(
    start_frequency=10,
    stop_frequency=100e3,
    number_of_points=100,
    variation='dec'
)

# Calculate -3dB point
magnitude = np.abs(analysis['2'].as_ndarray())
frequencies = analysis.frequency.as_ndarray()
cutoff_idx = np.argmin(np.abs(magnitude - 1/np.sqrt(2)))
print(f"Cutoff frequency: {frequencies[cutoff_idx]:.1f} Hz")
```

## Technical Details

### Build Configuration

- **ngspice version**: 44.2
- **Pyodide version**: 0.27.7
- **Emscripten version**: 3.1.58
- **libtool version**: 2.5.4 (required for wasm32-emscripten)
- **Build flags**:
  - `SIDE_MODULE_CFLAGS="-O2 -g0 -fPIC"`
  - `SIDE_MODULE_LDFLAGS="-O2 -g0 -s WASM_BIGINT -s SIDE_MODULE=1"`

### Wheel Structure

```
libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl
├── libngspice.libs/
│   └── libngspice.so          # WebAssembly shared library (5.6M uncompressed)
└── libngspice-44.2.dist-info/
    ├── METADATA               # Package metadata
    ├── WHEEL                  # Wheel specification
    ├── top_level.txt          # Top-level package name
    └── RECORD                 # File checksums
```

### Applied Patches

The build includes patches from Pyodide PR #5601:
1. **0001-keep-alive-API-functions.patch**: Ensures API functions aren't optimized away by the linker
2. **0001-no-hicum2.patch**: Disables HICUM2 model for compatibility

## Rebuilding from Source

To rebuild the library yourself:

```bash
# Run the build script
./build_ngspice_027.sh

# Or follow the detailed instructions in SUCCESSFUL_BUILD_027.md
```

The build process will:
1. Install libtool 2.5.4
2. Clone Pyodide 0.27.7
3. Apply PR #5601 patches
4. Build ngspice with Emscripten 3.1.58
5. Output `libngspice.so` to `/tmp/ngspice-build/dist/`

## References

- [Pyodide 0.27.7 Documentation](https://pyodide.org/en/0.27.7/)
- [InSpice on PyPI](https://pypi.org/project/inspice/)
- [ngspice Documentation](http://ngspice.sourceforge.net/docs.html)
- [Marimo Documentation](https://docs.marimo.io/)
- [Pyodide PR #5601](https://github.com/pyodide/pyodide/pull/5601) - Original ngspice patch

## License

- **ngspice**: BSD-3-Clause
- **InSpice**: GPL-3.0-or-later
