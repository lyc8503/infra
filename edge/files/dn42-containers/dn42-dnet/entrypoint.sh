#!/bin/bash
set -e

# DNET_IP: the IPv4 address for DNet-core
# DNET_NETMASK: netmask (e.g. 255.255.255.255)
# DNET_CIDR: CIDR for ip route (e.g. 172.20.42.240/32)

if [ -z "$DNET_IP" ] || [ -z "$DNET_NETMASK" ] || [ -z "$DNET_CIDR" ]; then
    echo "DNET_IP, DNET_NETMASK, DNET_CIDR must be set"
    exit 1
fi

# Ensure TAP device node exists
mkdir -p /dev/net
[ -c /dev/net/tap ] || mknod /dev/net/tap c 10 200 2>/dev/null || true
chmod 666 /dev/net/tap 2>/dev/null || true

echo "Starting DNet-core on $DNET_IP/$DNET_NETMASK..."
/opt/dnet/dnet-core dnet0 1280 11:45:14:19:19:81 "$DNET_IP" "$DNET_NETMASK" &
DNET_PID=$!

# Wait for dnet0 to appear, then bring it up and add route
until ip link show dnet0 >/dev/null 2>&1; do
    sleep 0.1
done
ip link set dev dnet0 up
ip route replace "$DNET_CIDR" dev dnet0

echo "DNet-core running, dnet0 up, route added."

wait $DNET_PID
