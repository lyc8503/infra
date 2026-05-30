FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Determine arch
RUN arch=$(uname -m) && \
    if [ "$arch" = "aarch64" ]; then lg_arch="arm64"; else lg_arch="amd64"; fi && \
    curl -fsSL "https://github.com/xddxdd/bird-lg-go/releases/download/v1.4.5/bird-lgproxy-go-v1.4.5-linux-${lg_arch}.tar.gz" -o /tmp/proxy.tar.gz && \
    curl -fsSL "https://github.com/xddxdd/bird-lg-go/releases/download/v1.4.5/bird-lg-go-v1.4.5-linux-${lg_arch}.tar.gz" -o /tmp/frontend.tar.gz && \
    mkdir -p /opt/bird-lg && \
    tar xzf /tmp/proxy.tar.gz -C /opt/bird-lg && mv /opt/bird-lg/bird-lgproxy-go /opt/bird-lg/proxy && \
    tar xzf /tmp/frontend.tar.gz -C /opt/bird-lg && mv /opt/bird-lg/bird-lg-go /opt/bird-lg/frontend && \
    chmod +x /opt/bird-lg/proxy /opt/bird-lg/frontend && \
    rm /tmp/proxy.tar.gz /tmp/frontend.tar.gz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
