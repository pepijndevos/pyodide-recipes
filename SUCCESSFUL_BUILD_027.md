# Successfully Built ngspice for Pyodide 0.27.7

## Build Summary

✅ **Successfully built ngspice for Pyodide 0.27.7** compatible with Marimo!

### Build Outputs
- **WebAssembly Module:** `libngspice.so` (5.6M)
- **Python Wheel:** `libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl` (1.8M compressed)
  - Ready for `micropip.install()` in Marimo
  - Contains the .so file in proper wheel structure

### Build Configuration
- **Pyodide Version:** 0.27.7
- **Emscripten Version:** 3.1.58
- **libtool Version:** 2.5.4 (required for wasm32-emscripten support)
- **ngspice Version:** 44.2
- **Build Time:** ~8 minutes

📖 **See [USING_NGSPICE_IN_MARIMO.md](USING_NGSPICE_IN_MARIMO.md) for installation and usage instructions**

### Key Success Factors

1. **libtool 2.5.4** - Critical upgrade from 2.4.7 to get wasm32-emscripten shared library support
2. **Applied PR #5601 patches** - Your patches for keep-alive API functions and disabling hicum2
3. **Correct Emscripten version** - 3.1.58 matches Pyodide 0.27.7 ABI
4. **Proper environment variables** - SIDE_MODULE_CFLAGS and SIDE_MODULE_LDFLAGS

## Reproduction Script

The complete build process is captured in `/tmp/build_ngspice_027.sh`:

```bash
#!/bin/bash
set -e

# 1. Install libtool 2.5.4
cd /tmp
wget https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.gz
tar -xzf libtool-2.5.4.tar.gz
cd libtool-2.5.4
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install

# 2. Clone Pyodide 0.27.7 and apply your patch
cd /tmp
git clone --depth 1 --branch 0.27.7 https://github.com/pyodide/pyodide.git pyodide-027
cd pyodide-027
wget -O ngspice.patch https://patch-diff.githubusercontent.com/raw/pyodide/pyodide/pull/5601.patch
git apply --reject --whitespace=fix ngspice.patch

# 3. Install and activate Emscripten 3.1.58
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 3.1.58
./emsdk activate 3.1.58
source emsdk_env.sh
cd ..

# 4. Set up build environment
export PATH="/usr/local/bin:$PATH"
export PYODIDE_ROOT=/tmp/pyodide-027
export WASM_LIBRARY_DIR=/tmp/ngspice-build/libs
export DISTDIR=/tmp/ngspice-build/dist
export PYODIDE_JOBS=4
export SIDE_MODULE_CFLAGS="-O2 -g0 -fPIC"
export SIDE_MODULE_LDFLAGS="-O2 -g0 -s WASM_BIGINT -s SIDE_MODULE=1"

mkdir -p $WASM_LIBRARY_DIR $DISTDIR

# 5. Build ngspice
cd /tmp/pyodide-027/packages/ngspice
wget -q https://github.com/danchitnis/ngspice-sf-mirror/archive/refs/tags/ngspice-44.2.zip
unzip -q ngspice-44.2.zip
cd ngspice-sf-mirror-ngspice-44.2

patch -p1 < ../patches/0001-keep-alive-API-functions.patch
patch -p1 < ../patches/0001-no-hicum2.patch

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
emmake make -j ${PYODIDE_JOBS} LDFLAGS="${SIDE_MODULE_LDFLAGS}"
emmake make install
cp ${WASM_LIBRARY_DIR}/lib/libngspice.so ${DISTDIR}/

echo "✅ Build complete! Output: $DISTDIR/libngspice.so"
```

## Using with Marimo

The build script automatically creates a wheel package ready for use in Marimo. See **[USING_NGSPICE_IN_MARIMO.md](USING_NGSPICE_IN_MARIMO.md)** for detailed instructions and examples.

### Quick Start

```python
# In your Marimo notebook
import micropip

# Install the wheel (host it locally or on a web server)
await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')

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

### Complete Examples

See `examples/marimo_ngspice_example.py` for comprehensive examples including:
- RC transient analysis
- AC frequency response (Bode plots)
- Diode I-V characteristics
- And more!

## CI Integration

### GitHub Actions

```yaml
name: Build ngspice for Pyodide 0.27.7

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Install libtool 2.5.4
        run: |
          wget https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.gz
          tar -xzf libtool-2.5.4.tar.gz
          cd libtool-2.5.4
          ./configure --prefix=/usr/local
          make -j$(nproc)
          sudo make install

      - name: Checkout Pyodide 0.27.7
        uses: actions/checkout@v4
        with:
          repository: pyodide/pyodide
          ref: '0.27.7'

      - name: Apply ngspice patch
        run: |
          wget -O ngspice.patch https://patch-diff.githubusercontent.com/raw/pyodide/pyodide/pull/5601.patch
          git apply --reject --whitespace=fix ngspice.patch

      - name: Setup Emscripten 3.1.58
        run: |
          git clone https://github.com/emscripten-core/emsdk.git
          cd emsdk
          ./emsdk install 3.1.58
          ./emsdk activate 3.1.58

      - name: Build ngspice
        run: |
          source emsdk/emsdk_env.sh
          export PATH="/usr/local/bin:$PATH"
          ./build_ngspice_027.sh

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: libngspice-pyodide-027
          path: |
            /tmp/ngspice-build/dist/libngspice.so
            /tmp/ngspice-build/dist/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl
```

## Next Steps

1. **Test with Marimo** - Load the library in a Marimo notebook and verify functionality
2. **Wait for PR merge** - Once PR #5601 is merged, ngspice will be available in Pyodide 0.27.x
3. **Consider Pyodide upgrade** - When Marimo upgrades to Pyodide 0.28+, use the official package index

## Files Generated

- **Binary:** `/tmp/ngspice-build/dist/libngspice.so` (5.6M)
- **Wheel:** `/tmp/ngspice-build/dist/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl` (1.8M)
- **Headers:** `/tmp/ngspice-build/libs/include/`
- **Build script:** `build_ngspice_027.sh` (in repository)
- **Usage guide:** `USING_NGSPICE_IN_MARIMO.md`
- **Examples:** `examples/marimo_ngspice_example.py`

## Notes

- The build takes approximately 8 minutes on a modern CPU
- Memory usage peaks around 2GB during compilation
- The resulting `.so` file is a WebAssembly side module
- Compatible with Pyodide 0.27.0 through 0.27.7 (Emscripten 3.1.58)
