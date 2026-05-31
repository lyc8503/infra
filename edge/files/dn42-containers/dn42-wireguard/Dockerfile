FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    procps wireguard-tools iproute2 iptables \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY wireguard/ /etc/wireguard/

ENTRYPOINT ["/entrypoint.sh"]
