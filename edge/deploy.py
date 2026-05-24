from pyinfra import host, local

# common APT packages, hostname, zram config
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

# if host.data.get("dn42"):
#     local.include("tasks/dn42/dn42_base.py")
#     local.include("tasks/dn42/ibgp.py")
#     if host.data.get("dn42", {}).get("dnet"):
#         local.include("tasks/dn42/dnet.py")
