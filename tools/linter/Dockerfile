FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install common dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    shellcheck=0.10.0-1 \
    && rm -rf /var/lib/apt/lists/*

# Install Hadolint
RUN curl -sSL -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 \
    && chmod +x /usr/local/bin/hadolint

# Install Ruff
RUN curl -sSL -o /tmp/ruff.tar.gz https://github.com/astral-sh/ruff/releases/download/0.9.6/ruff-x86_64-unknown-linux-gnu.tar.gz \
    && tar -xzf /tmp/ruff.tar.gz -C /tmp \
    && mv /tmp/ruff-x86_64-unknown-linux-gnu/ruff /usr/local/bin/ruff \
    && chmod +x /usr/local/bin/ruff \
    && rm -rf /tmp/ruff*

# Install Mypy
RUN pip3 install --no-cache-dir --break-system-packages mypy==1.15.0

# Install Trivy
RUN curl -sSL -o /tmp/trivy.deb https://github.com/aquasecurity/trivy/releases/download/v0.59.1/trivy_0.59.1_Linux-64bit.deb \
    && dpkg -i /tmp/trivy.deb \
    && rm /tmp/trivy.deb

# Create non-root user
RUN groupadd -g 1000 wbab && useradd -u 1000 -g wbab -m -s /bin/bash wbab

WORKDIR /workspace
RUN chown wbab:wbab /workspace

COPY scripts/lint-container.sh /usr/local/bin/wbab-lint-internal
RUN chmod +x /usr/local/bin/wbab-lint-internal

# Security: Run as non-root user
USER wbab

# Default to running the full suite
CMD ["/usr/local/bin/wbab-lint-internal"]
