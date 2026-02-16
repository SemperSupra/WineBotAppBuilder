FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    file \
    git \
    nsis \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

COPY tools/packaging/package-real.sh /usr/local/bin/wbab-package-real
COPY tools/packaging/package-fixture.sh /usr/local/bin/wbab-package-fixture
RUN chmod +x /usr/local/bin/wbab-package-real /usr/local/bin/wbab-package-fixture \
    && ln -s /usr/local/bin/wbab-package-real /usr/local/bin/wbab-package

# Security: Run as non-root user
RUN groupadd -g 1000 wbab && useradd -u 1000 -g wbab -m -s /bin/bash wbab
WORKDIR /workspace
RUN chown wbab:wbab /workspace
USER wbab

CMD ["bash"]
