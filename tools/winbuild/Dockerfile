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
    clang-tidy \
    wine \
    && rm -rf /var/lib/apt/lists/*

COPY tools/winbuild/build-real.sh /usr/local/bin/wbab-build-real
COPY tools/winbuild/build-fixture.sh /usr/local/bin/wbab-build-fixture
COPY tools/winbuild/lint-real.sh /usr/local/bin/wbab-lint-real
COPY tools/winbuild/test-real.sh /usr/local/bin/wbab-test-real
RUN chmod +x /usr/local/bin/wbab-build-real /usr/local/bin/wbab-build-fixture /usr/local/bin/wbab-lint-real /usr/local/bin/wbab-test-real \
    && ln -s /usr/local/bin/wbab-build-real /usr/local/bin/wbab-build \
    && ln -s /usr/local/bin/wbab-lint-real /usr/local/bin/wbab-lint \
    && ln -s /usr/local/bin/wbab-test-real /usr/local/bin/wbab-test

WORKDIR /workspace
CMD ["bash"]
