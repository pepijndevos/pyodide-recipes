# Building ngspice for Pyodide 0.27.7 - Build Options

There are three ways to build ngspice for Pyodide 0.27.7. Choose the method that works best for your environment.

## Option 1: Docker Build (Recommended)

**Best for:** Clean, reproducible builds using official Pyodide build tools.

The Docker build uses Python 3.12 in an isolated container and runs the proper `pyodide build` command.

### Prerequisites
- Docker installed ([Get Docker](https://docs.docker.com/get-docker/))

### Build
```bash
./build-with-docker.sh
```

This will:
1. Build a Docker image with Python 3.12, libtool 2.5.4, and all dependencies
2. Clone Pyodide 0.27.7 and apply PR #5601 patches
3. Run `pyodide build packages/ngspice` (the official way!)
4. Output the wheel to `dist/`

**Advantages:**
- ✅ Uses actual `pyodide build` command
- ✅ Completely isolated and reproducible
- ✅ No system pollution
- ✅ Works on Linux, macOS, and Windows (with Docker Desktop)

**Time:** ~10 minutes (first build), ~5 minutes (subsequent builds with cached image)

---

## Option 2: Conda Build

**Best for:** When Docker isn't available but you have conda/mamba installed.

Uses conda to get Python 3.12 and then runs the proper `pyodide build` command.

### Prerequisites
- Conda or Mamba installed ([Get Miniconda](https://docs.conda.io/en/latest/miniconda.html))

### Build
```bash
./build-with-conda.sh
```

This will:
1. Create a conda environment with Python 3.12
2. Install libtool 2.5.4 and pyodide-build
3. Clone Pyodide 0.27.7 and apply patches
4. Run `pyodide build packages/ngspice`
5. Output the wheel to `dist/`

**Advantages:**
- ✅ Uses actual `pyodide build` command
- ✅ Reproducible Python environment
- ✅ No Docker required
- ✅ Can reuse environment for multiple builds

**To clean up:**
```bash
conda env remove -n pyodide-ngspice-builder
```

**Time:** ~15 minutes (first build), ~5 minutes (subsequent builds)

---

## Option 3: Manual Build Script

**Best for:** When neither Docker nor conda is available, or you need maximum control.

A self-contained bash script that sets up everything from scratch and follows the `meta.yaml` recipe.

### Prerequisites
- Linux or macOS
- bash, wget, git, make, gcc, autoconf (standard build tools)
- sudo access (for installing libtool)

### Build
```bash
./build_ngspice_complete.sh
```

This will:
1. Install libtool 2.5.4 system-wide (requires sudo)
2. Clone Pyodide 0.27.7 and Emscripten 3.1.58
3. Apply PR #5601 patches
4. Build ngspice following the `packages/libngspice/meta.yaml` recipe
5. Create the wheel package
6. Output to `/tmp/ngspice-pyodide-build/dist/`

**Advantages:**
- ✅ No special tools required
- ✅ Follows meta.yaml recipe closely
- ✅ Self-contained (downloads everything needed)
- ✅ Good for CI/CD pipelines

**Disadvantages:**
- ⚠️ Installs libtool system-wide (requires sudo)
- ⚠️ Doesn't use `pyodide build` command directly
- ⚠️ Leaves build artifacts in /tmp

**Time:** ~10 minutes

---

## Comparison Table

| Feature | Docker | Conda | Manual Script |
|---------|--------|-------|---------------|
| Uses `pyodide build` | ✅ Yes | ✅ Yes | ❌ No (follows recipe manually) |
| Requires sudo | ❌ No | ❌ No | ⚠️ Yes (for libtool) |
| System isolation | ✅ Full | ⚠️ Python only | ❌ None |
| Reproducibility | ✅ Excellent | ✅ Good | ⚠️ Fair |
| Easy cleanup | ✅ Yes | ✅ Yes | ⚠️ Manual |
| Works on Windows | ✅ Yes | ⚠️ Limited | ❌ No |
| Build time (first) | ~10 min | ~15 min | ~10 min |
| Build time (cached) | ~5 min | ~5 min | ~10 min |

---

## Output

All methods produce the same output in their respective `dist/` directories:

```
libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl  (1.8M)
```

This wheel can be installed in Marimo with:

```python
import micropip
await micropip.install('http://localhost:8000/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')
await micropip.install('inspice')
```

---

## Pre-built Wheel

If you don't want to build from source, a pre-built wheel is available in the `releases/` directory of this repository.

See [releases/README.md](releases/README.md) for installation instructions.

---

## Troubleshooting

### Docker Issues

**Error: "Cannot connect to Docker daemon"**
- Make sure Docker is running: `docker ps`
- On Linux, add your user to docker group: `sudo usermod -aG docker $USER`

**Error: "permission denied while trying to connect"**
- Run with sudo: `sudo ./build-with-docker.sh`
- Or configure Docker to run without sudo (recommended)

### Conda Issues

**Error: "conda: command not found"**
- Install Miniconda: https://docs.conda.io/en/latest/miniconda.html
- Restart your terminal after installation

**Error: "environment.yml not found"**
- Make sure you're running the script from the repository root

### Manual Script Issues

**Error: "libtool: command not found" after installation**
- Run: `hash -r` to refresh PATH
- Or start a new terminal

**Error: "Permission denied" for /tmp/ngspice-pyodide-build**
- Run: `sudo chown -R $USER /tmp/ngspice-pyodide-build`

---

## CI/CD Integration

### GitHub Actions with Docker

```yaml
name: Build ngspice
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build with Docker
        run: ./build-with-docker.sh
      - uses: actions/upload-artifact@v4
        with:
          name: ngspice-wheel
          path: dist/*.whl
```

### GitHub Actions with Conda

```yaml
name: Build ngspice
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: conda-incubator/setup-miniconda@v3
        with:
          python-version: 3.12
      - name: Build with Conda
        run: ./build-with-conda.sh
        shell: bash -el {0}
      - uses: actions/upload-artifact@v4
        with:
          name: ngspice-wheel
          path: dist/*.whl
```

---

## Next Steps

After building, see:
- **[USING_NGSPICE_IN_MARIMO.md](USING_NGSPICE_IN_MARIMO.md)** - Installation and usage guide
- **[examples/marimo_ngspice_example.py](examples/marimo_ngspice_example.py)** - Example circuits
