#!/bin/bash
set -e

for conf in /etc/wireguard/dn42_*.conf; do
    [ -f "$conf" ] || continue
    iface=$(basename "$conf" .conf)
    echo "Bringing up $iface..."
    wg-quick down "$conf" 2>/dev/null || true
    wg-quick up "$conf" || echo "WARNING: Failed to bring up $iface, skipping..."
done

echo "All WireGuard interfaces up."
exec sleep infinity
