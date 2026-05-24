from pyinfra import host, local

# common APT packages, hostname, zram config, BBR
local.include("tasks/common.py")

# fancy shell tools
local.include("tasks/fancy.py")

# metrics and logging
if host.data.get("push_endpoint"):
    local.include("tasks/metrics.py")

# xray (vmess / hysteria2) and registration
if host.data.get("proxy"):
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
# if host.data.get("dn42"):
#     local.include("tasks/dn42.py")
