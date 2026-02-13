FROM mcr.microsoft.com/devcontainers/base:debian-12

# Install dependencies needed to drive the wbab lifecycle (Docker-in-Docker, Python, JQ, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    shellcheck \
    cmake \
    make \
    python3-pip \
    python3-venv \
    jq \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Note: wbab toolchain is available via the workspace mount, not baked into the image.
# This ensures consistency between devcontainer and standalone usage.
ENV PATH="/workspace/tools:/workspace/scripts:${PATH}"
