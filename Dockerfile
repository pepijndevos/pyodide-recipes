# Dockerfile for building ngspice wheel for Pyodide
# Mirrors the pyodide-recipes CI workflow

FROM condaforge/mambaforge:latest

WORKDIR /build

# Copy the entire pyodide-recipes repository
COPY . /build/

# Install conda environment from environment.yml
RUN mamba env update -n base -f environment.yml && \
    mamba clean -afy

# Install pyodide-build from the repo's pyodide-build subdirectory
RUN python -m pip install ./pyodide-build/ && \
    pyodide xbuildenv install

# Install and patch emscripten (following CI workflow)
RUN python tools/install_and_patch_emscripten.py

# Source emscripten environment
ENV PATH="/build/emsdk:/build/emsdk/upstream/emscripten:${PATH}"
ENV EMSDK="/build/emsdk"

# Build script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "======================================================"\n\
echo "Building libngspice using pyodide build-recipes"\n\
echo "======================================================"\n\
source emsdk/emsdk_env.sh\n\
mkdir -p repodata build-logs\n\
pyodide build-recipes libngspice --install --install-dir=./repodata --log-dir=build-logs\n\
echo ""\n\
echo "======================================================"\n\
echo "Build complete!"\n\
echo "======================================================"\n\
ls -lh repodata/*.whl\n\
if [ -d "/output" ]; then\n\
  cp -v repodata/*.whl /output/\n\
fi' > /build/build.sh && chmod +x /build/build.sh

CMD ["/build/build.sh"]

# Build outputs will be in /build/repodata/
VOLUME ["/output"]
