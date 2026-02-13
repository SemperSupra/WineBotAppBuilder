FROM mcr.microsoft.com/devcontainers/base:debian-12

RUN apt-get update && apt-get install -y --no-install-recommends 
    shellcheck 
    cmake 
    make 
    python3-pip 
    python3-venv 
    jq 
    && rm -rf /var/lib/apt/lists/*

# Install wbab to path for convenience
COPY tools/wbab /usr/local/bin/wbab
RUN chmod +x /usr/local/bin/wbab

# Add workspace to path for other scripts
ENV PATH="/workspace/tools:/workspace/scripts:${PATH}"
