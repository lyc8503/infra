import json
from io import StringIO

from pyinfra import host
from pyinfra.operations import files, server, systemd
from pyinfra.facts.server import Arch
from pyinfra.facts.files import File

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())

app_ver = "v26.3.27"
arch = host.get_fact(Arch)
arch_suffix = "arm64-v8a" if arch == "aarch64" else "64"


files.directory(
    name="Ensure /opt/xray exists",
    path="/opt/xray",
)

files.download(
    name="Download xray release",
    src=f"https://github.com/XTLS/Xray-core/releases/download/{app_ver}/Xray-linux-{arch_suffix}.zip",
    dest="/tmp/xray.zip",
)

server.shell(
    name="Extract xray",
    commands=["unzip -o /tmp/xray.zip -d /opt/xray"],
    _if=lambda: not host.get_fact(File, path="/opt/xray/xray"),
)

server.shell(
    name="Generate self-signed TLS cert",
    commands=[
        "openssl req -x509 -newkey rsa:3072 -keyout /opt/xray/server.key -out /opt/xray/server.crt -sha256 -days 3650 -nodes -subj '/CN=server'",
    ],
    _if=lambda: not host.get_fact(File, path="/opt/xray/server.key"),
)

files.file(
    name="Set TLS cert permission",
    path="/opt/xray/server.key",
    mode="644",
)

config_json = {
    "log": {"loglevel": "warning"},
    "inbounds": [
        {
            "port": d.proxy.vmess_port,
            "protocol": "vmess",
            "settings": {
                "clients": [{"id": d.proxy.v2_uuid}],
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
            },
        },
        {
            "port": d.proxy.hysteria2_port,
            "protocol": "hysteria",
            "settings": {
                "version": 2,
                "clients": [
                    {
                        "auth": d.proxy.v2_uuid,
                    }
                ],
            },
            "streamSettings": {
                "network": "hysteria",
                "security": "tls",
                "hysteriaSettings": {
                    "version": 2,
                    "auth": d.proxy.v2_uuid,
                },
                "tlsSettings": {
                    "serverName": "server",
                    "alpn": ["h3"],
                    "certificates": [
                        {
                            "certificateFile": "/opt/xray/server.crt",
                            "keyFile": "/opt/xray/server.key",
                        }
                    ],
                    "maxVersion": "1.3",
                    "minVersion": "1.3",
                },
            },
        },
    ],
    "outbounds": [{"protocol": "freedom", "settings": {}}],
}


config = files.put(
    name="Put xray config",
    src=StringIO(json.dumps(config_json, indent=2) + "\n"),
    dest="/opt/xray/config.json",
)

service_content = """[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
DynamicUser=yes
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/opt/xray/xray run -config /opt/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
"""

files.put(
    name="Put xray systemd service",
    src=StringIO(service_content),
    dest="/etc/systemd/system/xray.service",
)

ipv4_register = (
    f"SELF_PUBLIC_IP=$(curl -4 -s https://ifconfig.me/ip)\n"
    f'if [ -n "$SELF_PUBLIC_IP" ]; then\n'
    f"  curl -G '{d.proxy.sub_server}?token={d.proxy.reg_password}&id={host.name}_vmess&traffic={d.proxy.traffic}' "
    f'--data-urlencode "subscription={{name: {host.name}_vmess, type: vmess, server: $SELF_PUBLIC_IP, port: {d.proxy.vmess_port}, uuid: {d.proxy.v2_uuid}, alterId: 0, cipher: auto, network: tcp, udp: true}}"\n'
    f"  curl -G '{d.proxy.sub_server}?token={d.proxy.reg_password}&id={host.name}_hy2&traffic={d.proxy.traffic}' "
    f'--data-urlencode "subscription={{name: {host.name}_hy2, type: hysteria2, server: $SELF_PUBLIC_IP, port: {d.proxy.hysteria2_port}, password: {d.proxy.v2_uuid}, skip-cert-verify: true, client-fingerprint: chrome}}"\n'
    f"fi"
)

ipv6_register = ""
if d.proxy.ipv6_sub:
    ipv6_register = (
        f"\n\nSELF_PUBLIC_IPV6=$(curl -6 -s https://ifconfig.me/ip)\n"
        f"curl -G '{d.proxy.sub_server}?token={d.proxy.reg_password}&id={host.name}_v6_vmess&traffic={d.proxy.traffic}' "
        f'--data-urlencode "subscription={{name: {host.name}_v6_vmess, type: vmess, server: $SELF_PUBLIC_IPV6, port: {d.proxy.vmess_port}, uuid: {d.proxy.v2_uuid}, alterId: 0, cipher: auto, network: tcp, udp: true}}"\n'
        f"curl -G '{d.proxy.sub_server}?token={d.proxy.reg_password}&id={host.name}_v6_hy2&traffic={d.proxy.traffic}' "
        f'--data-urlencode "subscription={{name: {host.name}_v6_hy2, type: hysteria2, server: $SELF_PUBLIC_IPV6, port: {d.proxy.hysteria2_port}, password: {d.proxy.v2_uuid}, skip-cert-verify: true, client-fingerprint: chrome}}"\n'
    )

register_content = f"#!/bin/bash\n{ipv4_register}{ipv6_register}\n"

files.put(
    name="Put xray register script",
    src=StringIO(register_content),
    dest="/opt/xray/register.sh",
    mode="755",
)

server.crontab(
    name="Set up xray registration cron",
    command="/opt/xray/register.sh",
    minute="*/5",
)

systemd.service(
    name="Enable and start xray",
    service="xray",
    running=True,
    enabled=True,
    daemon_reload=config.changed,
    restarted=config.changed,
)
