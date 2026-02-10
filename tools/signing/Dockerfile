FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    openssl \
    osslsigncode \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash"]
