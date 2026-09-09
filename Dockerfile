# Better-ComfyUI Docker image
#
# Source:    this repository (Better-ComfyUI fork, v0.34.0)
# Pattern:   ComfyUI official docker image (nvidia/cuda base + torch cu128)
# Target:    RTX 5080 (Blackwell, sm_120) — requires CUDA 12.8+ / cu128 wheels
#
# Build:
#   docker build \
#     -t tuiteraz/better-comfyui:latest \
#     -t tuiteraz/better-comfyui:250b2e95 .
#
# Run (compose handles this in behemoth-lan):
#   docker run --gpus all -p 8188:8188 \
#     -v /data:/opt/comfyui/data tuiteraz/better-comfyui:latest
#
# Notes:
#   - The entrypoint respects the CLI_ARGS env var (e.g. --enable-manager --lowvram).
#   - xformers is intentionally NOT preinstalled: compose may set ATTN_BACKEND=xformers,
#     but ComfyUI falls back to pytorch/sdpa attention cleanly. Add it here later
#     (version-locked to the torch below) if xformers attention is required.

FROM nvidia/cuda:12.8.1-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 (LTS) — runtime dependency for ComfyUI-Manager (matches the live image).
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Python runtime via conda (3.14 — confirmed against the live image's
# /opt/conda/lib/python3.14; the older checked-in comment's runtime claim was wrong)
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/mf.sh \
    && /bin/bash /tmp/mf.sh -b -p /opt/conda \
    && rm /tmp/mf.sh
ENV PATH=/opt/conda/bin:$PATH

# Torch cu128 (Blackwell-compatible). Installed BEFORE requirements.txt so the
# unpinned `torch` entry there does not pull a CPU wheel.
RUN /opt/conda/bin/pip install --no-cache-dir \
        torch==2.9.1 \
        torchvision==0.24.1 \
        torchaudio==2.9.1 \
        --index-url https://download.pytorch.org/whl/cu128

# Repository dependencies
COPY requirements.txt /tmp/requirements.txt
RUN /opt/conda/bin/pip install --no-cache-dir -r /tmp/requirements.txt

# llama-cpp-python with CUDA support (required by ComfyUI-QwenVL node)
# Python 3.14 has no pre-built CUDA wheel, so we compile from source
RUN apt-get update && apt-get install -y --no-install-recommends \
        cmake \
        libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && CMAKE_ARGS="-DGGML_CUDA=on -DGGML_CUBLAS=on" /opt/conda/bin/pip install --no-cache-dir llama-cpp-python

# ComfyUI source (this fork)
WORKDIR /opt/comfyui
COPY . /opt/comfyui

# ComfyUI-Manager requirements (matches the live image layer; file is COPYed above)
RUN /opt/conda/bin/pip install --no-cache-dir -r /opt/comfyui/manager_requirements.txt

# Own the conda env and the ComfyUI tree (container runs as user 1000:1000; matches
# the live image layer)
RUN chown -R 1000:1000 /opt/conda /opt/comfyui

# MCP stack pins (baked into the image; comfy-mcp is the stdio MCP server,
# mcp-sse-wrapper.py exposes it over SSE on :8189). Pins verified against the live
# image (comfy-cli 1.20.0, comfy-mcp 0.10.0) and ADR-002. The mcp-SDK-based wrapper
# replaces mcp-proxy (which requires mcp<2 and is incompatible with comfy-mcp's
# mcp 2.x dependency).
RUN /opt/conda/bin/pip install --no-cache-dir \
        comfy-mcp==0.10.0 comfy-cli>=1.14.0

# MCP SSE wrapper (mcp-SDK-based replacement for mcp-proxy; managed child of
# docker-entrypoint.sh; no nohup supervisor).
# NOTE: lives in /opt/comfyui (repo tree) NOT /app — compose bind-mounts ./data:/app
# which would shadow a baked /app script.
COPY mcp-sse-launcher.sh /mcp-sse-launcher.sh
RUN chmod +x /mcp-sse-launcher.sh

# Entrypoint: model directories + custom-node requirements + CLI_ARGS support
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8188 8189

# Correct python path (the old lecode-based image pointed at /opt/venv/bin/python3,
# which does not exist → container perpetually "unhealthy" while the API worked).
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
    CMD /opt/conda/bin/python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8188/api/system_stats', timeout=5)" || exit 1

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
