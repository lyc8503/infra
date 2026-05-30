FROM debian:stable-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates cmake g++ git make \
    && rm -rf /var/lib/apt/lists/*

ARG DNET_REPO=https://github.com/lyc8503/DNet-core.git
ARG DNET_COMMIT=b6aa2c4

WORKDIR /build
RUN git clone "$DNET_REPO" . && git checkout "$DNET_COMMIT"

# DNSRecord.h will be provided at build time or mounted at runtime
COPY DNSRecord.h /build/layers/L7/DNSRecord.h

RUN mkdir -p build && cd build && cmake .. && make -j$(nproc)

FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/build/DNet /opt/dnet/dnet-core
RUN chmod +x /opt/dnet/dnet-core

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
