# Quick Start - Building ngspice for Marimo

Choose your preferred build method:

## 🚀 Pre-built Wheel (No Build Required!)

Download directly from [releases/](releases/):
```python
import micropip
await micropip.install('https://github.com/pepijndevos/pyodide-recipes/raw/claude/check-pyodide-ngspice-build-011CV1tZ6hoEg5itwAYbFAiJ/releases/libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl')
await micropip.install('inspice')
```

## 🏗️ Build from Source

| Method | Command | Best For |
|--------|---------|----------|
| **🐳 Docker** | `./build-with-docker.sh` | Most users - uses official `pyodide build` |
| **🐍 Conda** | `./build-with-conda.sh` | When Docker unavailable - uses `pyodide build` |
| **📜 Manual** | `./build_ngspice_complete.sh` | Anywhere - self-contained script |

All produce: `libngspice-44.2-cp312-cp312-pyodide_2024_0_wasm32.whl`

📖 **Full details:** [BUILD_OPTIONS.md](BUILD_OPTIONS.md)
📖 **Usage guide:** [USING_NGSPICE_IN_MARIMO.md](USING_NGSPICE_IN_MARIMO.md)
📖 **Examples:** [examples/marimo_ngspice_example.py](examples/marimo_ngspice_example.py)
