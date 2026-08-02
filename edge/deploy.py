import os
from pyinfra import host, local

MODULE = os.environ.get("MODULE", "")

# a fast path to only update DN42 related stuff
if MODULE == "dn42":
    if host.data.get("dn42"):
        local.include("tasks/dn42.py")
else:
    # common APT packages, hostname, zram config, BBR
    local.include("tasks/common.py")

    # fancy shell tools
    local.include("tasks/fancy.py")

    # metrics and logging
    if host.data.get("push_endpoint"):
        local.include("tasks/metrics.py")

    # usque (WARP MASQUE) then xray (vless / hysteria2) and registration
    if host.data.get("proxy"):
        local.include("tasks/usque.py")
        local.include("tasks/xray.py")

    # misc server (sub / tgbot / log)
    if host.data.get("misc"):
        local.include("tasks/containers.py")
        local.include("tasks/caddy.py")

    # tor relay
    if host.data.get("tor_relay"):
        local.include("tasks/tor.py")

    # frp server
    if host.data.get("frps_token"):
        local.include("tasks/frps.py")

    # DN42 (bird / wireguard / dnet / looking glass / smokeping)
    if host.data.get("dn42"):
        local.include("tasks/dn42.py")
