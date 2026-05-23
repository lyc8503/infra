from pyinfra import host, local

local.include("tasks/common.py")

if host.data.get("push_endpoint"):
    local.include("tasks/metrics.py")

if host.data.get("proxy"):
    local.include("tasks/xray.py")

if host.data.get("misc"):
    local.include("tasks/containers.py")
    local.include("tasks/caddy.py")

# if host.data.get("dn42"):
#     local.include("tasks/dn42/dn42_base.py")
#     local.include("tasks/dn42/ibgp.py")
#     if host.data.get("dn42", {}).get("dnet"):
#         local.include("tasks/dn42/dnet.py")
