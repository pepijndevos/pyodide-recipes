# Building libngspice for Pyodide 0.27.7 (Marimo)

**Marimo uses:** Pyodide 0.27.7 with Emscripten 3.1.58

**Important:** The libngspice recipe was added to pyodide-recipes in August 2025 and doesn't exist in Pyodide 0.27.7. You have three options:

## Option 1: Build from Main Pyodide Repository (Recommended for Production)

Build ngspice as part of a full Pyodide 0.27.7 build with the recipe backported:

```bash
# Clone main Pyodide repository
git clone --recurse-submodules https://github.com/pyodide/pyodide.git
cd pyodide
git checkout 0.27.7
git submodule update --init --recursive

# Install build dependencies
# On Ubuntu/Debian:
sudo apt-get install build-essential git cmake ccache libtool automake autoconf \
    texinfo bison flex gfortran f2c

# Install libtool 2.5.4+ (required for wasm32-emscripten support)
cd /tmp
wget https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.gz
tar -xzf libtool-2.5.4.tar.gz
cd libtool-2.5.4
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install

# Back to pyodide directory
cd /path/to/pyodide

# Copy libngspice recipe from pyodide-recipes
mkdir -p packages/libngspice
# Copy meta.yaml and patches from pyodide-recipes repository

# Build Pyodide with ngspice
make

# The built package will be in dist/
```

## Option 2: Build Standalone Package (Experimental)

Build just the ngspice package against Pyodide 0.27.7 release artifacts:

```bash
# Install Python 3.13 and create environment
conda create -n pyodide-027 python=3.13
conda activate pyodide-027

# Install pyodide-build matching 0.27.7
pip install pyodide-build==0.27.7

# Install libtool 2.5.4+
wget https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.gz
tar -xzf libtool-2.5.4.tar.gz
cd libtool-2.5.4
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install
cd ..

# Install Emscripten 3.1.58
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 3.1.58
./emsdk activate 3.1.58
source emsdk_env.sh
cd ..

# Download xbuildenv for 0.27.7
pyodide xbuildenv install \
  --url https://github.com/pyodide/pyodide/releases/download/0.27.7/xbuildenv-0.27.7.tar.bz2

# Clone pyodide-recipes and build
git clone https://github.com/pyodide/pyodide-recipes.git
cd pyodide-recipes/packages/libngspice

# Build the package
PATH="/usr/local/bin:$PATH" pyodide build .

# Output will be in dist/
```

## Option 3: Wait for Marimo to Upgrade

The easiest solution is to wait for Marimo to upgrade to Pyodide 0.28+, where ngspice will be available from the official package index:

```python
# In Marimo with Pyodide 0.28+:
import micropip
await micropip.install(
    'libngspice',
    index_urls='https://pypi.anaconda.org/pyodide/simple'
)
```

## Key Requirements

1. **libtool 2.5.4 or newer** - Required for wasm32-emscripten shared library support
2. **Emscripten 3.1.58** - Matches Pyodide 0.27.7 ABI
3. **Python 3.13** - Required by pyodide-build tools
4. **Build tools**: autoconf, automake, bison, cmake, ccache, gfortran

## Testing the Built Package

Once built, you can test it in Marimo:

```python
# In Marimo notebook
import micropip
# Upload your built .whl file and install it
await micropip.install('/path/to/libngspice-44.2-py3-none-any.whl')

# Test the library
import ctypes
libngspice = ctypes.CDLL('libngspice.so')
print("ngspice loaded successfully!")
```

## CI/Automation

For CI builds:

```yaml
# GitHub Actions example
- name: Install libtool 2.5.4
  run: |
    wget https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.gz
    tar -xzf libtool-2.5.4.tar.gz
    cd libtool-2.5.4
    ./configure --prefix=/usr/local
    make -j$(nproc)
    sudo make install

- name: Setup Pyodide Build Environment
  run: |
    pip install pyodide-build==0.27.7
    pyodide xbuildenv install --url \
      https://github.com/pyodide/pyodide/releases/download/0.27.7/xbuildenv-0.27.7.tar.bz2

- name: Build ngspice
  run: |
    cd pyodide-recipes/packages/libngspice
    PATH="/usr/local/bin:$PATH" pyodide build .
```

## Known Issues

1. **Version Mismatch**: Building with current pyodide-recipes tools targets Pyodide 0.28+ by default
2. **No Official 0.27.7 Package**: ngspice wasn't in the Pyodide 0.27.7 release
3. **Libtool Requirement**: Older libtool versions will fail with "cannot build a shared library" error

## Recommendation

Given the complexity, I recommend **Option 3** (wait for Marimo to upgrade to Pyodide 0.28+) unless you have an urgent need. The ngspice package will then be available from the official Anaconda index without custom builds.
