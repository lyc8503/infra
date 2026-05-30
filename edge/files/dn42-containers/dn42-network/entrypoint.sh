#!/bin/bash
set -e

# DN42_IPV4_ADDRESSES: space/comma-separated IPv4 addresses
# DN42_IPV6_ADDRESSES: space/comma-separated IPv6 addresses
# DN42_DNET_IP: DNet-core IPv4 address (optional)
# DN42_DNET_CIDR: DNet-core CIDR (optional)

IFS=', ' read -r -a ipv4_list <<< "$DN42_IPV4_ADDRESSES"
IFS=', ' read -r -a ipv6_list <<< "$DN42_IPV6_ADDRESSES"

# Create dn42dummy0 and add addresses
ip link add dn42dummy0 type dummy 2>/dev/null || true
ip link set dn42dummy0 up

for addr in "${ipv4_list[@]}"; do
    [ -n "$addr" ] && ip addr add "$addr/32" dev dn42dummy0 2>/dev/null || true
done
for addr in "${ipv6_list[@]}"; do
    [ -n "$addr" ] && ip addr add "$addr/128" dev dn42dummy0 2>/dev/null || true
done

# sysctl for rp_filter on dummy
echo 0 > /proc/sys/net/ipv4/conf/dn42dummy0/rp_filter 2>/dev/null || true

# Create /dev/net/tap for DNet-core (if DNet is configured)
if [ -n "$DN42_DNET_IP" ]; then
    mkdir -p /dev/net
    [ -c /dev/net/tap ] || mknod /dev/net/tap c 10 200
    chmod 666 /dev/net/tap

    # NAT rules for DNet DNS (using eth0 as the external interface in the sandbox netns)
    iptables -t nat -C POSTROUTING -s "$DN42_DNET_CIDR" -o eth0 -j MASQUERADE 2>/dev/null || \
        iptables -t nat -I POSTROUTING -s "$DN42_DNET_CIDR" -o eth0 -j MASQUERADE

    iptables -C FORWARD -d "$DN42_DNET_IP" -p udp --dport 53 -j ACCEPT 2>/dev/null || \
        iptables -I FORWARD -d "$DN42_DNET_IP" -p udp --dport 53 -j ACCEPT

    iptables -C FORWARD -s "$DN42_DNET_IP" -p udp --sport 53 -j ACCEPT 2>/dev/null || \
        iptables -I FORWARD -s "$DN42_DNET_IP" -p udp --sport 53 -j ACCEPT
fi

echo "dn42-network setup complete"
