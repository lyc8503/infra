#!/bin/bash
set -e

# Wait for dn42dummy0 to be created
until ip link show dn42dummy0 >/dev/null 2>&1; do
    echo "Waiting for dn42dummy0..."
    sleep 1
done

# Wait for at least some WireGuard interfaces to appear
# (BIRD can still start with 0 WG interfaces, but we prefer waiting)
echo "Waiting for WireGuard interfaces..."
for i in $(seq 1 30); do
    if ls /sys/class/net/dn42_* >/dev/null 2>&1; then
        echo "WireGuard interfaces found."
        break
    fi
    sleep 1
done

mkdir -p /run/bird

echo "Starting BIRD..."
exec bird -f -c /etc/bird/bird.conf
