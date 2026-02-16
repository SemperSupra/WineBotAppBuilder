FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    openssl \
    osslsigncode \
    && rm -rf /var/lib/apt/lists/*

# Security: Run as non-root user
RUN groupadd -g 1000 wbab && useradd -u 1000 -g wbab -m -s /bin/bash wbab
WORKDIR /workspace
RUN chown wbab:wbab /workspace
USER wbab

CMD ["bash"]
