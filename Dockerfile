# Docker image for building ngspice for Pyodide 0.27.7
# This uses Python 3.12 so we can properly use pyodide-build tools

FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    autoconf \
    automake \
    pkg-config \
    bison \
    flex \
    gperf \
    texinfo \
    unzip \
    cmake \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install libtool 2.5.4 (required for wasm32-emscripten support)
WORKDIR /tmp
RUN wget -q https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.gz && \
    tar -xzf libtool-2.5.4.tar.gz && \
    cd libtool-2.5.4 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf libtool-2.5.4*

# Create working directory
WORKDIR /build

# Clone Pyodide 0.27.7
RUN git clone --depth 1 --branch 0.27.7 https://github.com/pyodide/pyodide.git

WORKDIR /build/pyodide

# Install Emscripten 3.1.58
RUN git clone https://github.com/emscripten-core/emsdk.git && \
    cd emsdk && \
    ./emsdk install 3.1.58 && \
    ./emsdk activate 3.1.58

# Install pyodide-build (will work with Python 3.12)
RUN pip install --no-cache-dir pyodide-build

# Apply ngspice patches from PR #5601
RUN wget -q -O /tmp/ngspice.patch https://patch-diff.githubusercontent.com/raw/pyodide/pyodide/pull/5601.patch && \
    git apply --reject --whitespace=fix /tmp/ngspice.patch || true && \
    rm /tmp/ngspice.patch

# Verify ngspice package was added
RUN test -d packages/ngspice || (echo "ERROR: ngspice package not found" && exit 1)

# Set environment variables for Pyodide build
ENV PATH="/build/pyodide/emsdk:/build/pyodide/emsdk/upstream/emscripten:/usr/local/bin:${PATH}"
ENV PYODIDE_ROOT="/build/pyodide"

# Build script
COPY docker-build.sh /build/docker-build.sh
RUN chmod +x /build/docker-build.sh

# Default command: build ngspice and create wheel
CMD ["/build/docker-build.sh"]

# Build outputs will be in /build/pyodide/dist/
VOLUME ["/output"]
