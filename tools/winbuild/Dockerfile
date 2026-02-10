FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    cmake \
    g++ \
    gcc-mingw-w64 \
    git \
    make \
    mingw-w64 \
    ninja-build \
    pkg-config \
    python3 \
    && rm -rf /var/lib/apt/lists/*

COPY tools/winbuild/build-real.sh /usr/local/bin/wbab-build-real
COPY tools/winbuild/build-fixture.sh /usr/local/bin/wbab-build-fixture
RUN chmod +x /usr/local/bin/wbab-build-real /usr/local/bin/wbab-build-fixture \
    && ln -s /usr/local/bin/wbab-build-real /usr/local/bin/wbab-build

WORKDIR /workspace
CMD ["bash"]
