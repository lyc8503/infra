#!/bin/bash
set -e

for conf in /etc/wireguard/dn42_*.conf; do
    [ -f "$conf" ] || continue
    echo "Bringing up $(basename "$conf" .conf)..."
    wg-quick up "$conf"
done

echo "All WireGuard interfaces up."
exec sleep infinity
