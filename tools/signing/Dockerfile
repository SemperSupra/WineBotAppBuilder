FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    openssl \
    osslsigncode \
    && rm -rf /var/lib/apt/lists/*

COPY tools/signing/sign-real.sh /usr/local/bin/wbab-sign-real
COPY tools/signing/sign-fixture.sh /usr/local/bin/wbab-sign-fixture
RUN chmod +x /usr/local/bin/wbab-sign-real /usr/local/bin/wbab-sign-fixture \
    && ln -s /usr/local/bin/wbab-sign-real /usr/local/bin/wbab-sign

# Security: Create non-root user
RUN groupadd -g 1000 wbab && useradd -u 1000 -g wbab -m -s /bin/bash wbab
WORKDIR /workspace
RUN chown wbab:wbab /workspace

# Security: Run as non-root user by default. The host wrapper may select the
# invoking host UID/GID for dev-cert mode so restrictive bind-mounted cert
# permissions remain readable without escalating the container to root.
USER wbab

CMD ["bash"]
