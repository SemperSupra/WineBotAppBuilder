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

# Install Trivy from an immutable upstream release and verify the exact asset
# digest before installation. The prior v0.59.1 pin did not exist and caused
# lint to fail during validator bootstrap rather than execute against the code.
ARG TRIVY_VERSION=0.74.0
ARG TRIVY_LINUX64_DEB_SHA256=cf1e32ec8d4d8823e023096a28cadb14f5b5123ce03f201fb633c5b76aa712dd
RUN set -eux; \
    curl --fail --location --retry 3 --retry-all-errors \
      -o /tmp/trivy.deb \
      "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.deb"; \
    echo "${TRIVY_LINUX64_DEB_SHA256}  /tmp/trivy.deb" | sha256sum -c -; \
    dpkg -i /tmp/trivy.deb; \
    rm /tmp/trivy.deb

# Install CycloneDX CLI for SBOM validation
RUN curl -sSL -o /tmp/cyclonedx-cli.tar.gz https://github.com/CycloneDX/cyclonedx-cli/releases/download/v0.25.1/cyclonedx-linux-amd64.tar.gz \
    && tar -xzf /tmp/cyclonedx-cli.tar.gz -C /tmp \
    && mv /tmp/cyclonedx-linux-amd64/cyclonedx /usr/local/bin/cyclonedx \
    && chmod +x /usr/local/bin/cyclonedx \
    && rm -rf /tmp/cyclonedx*

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
