from io import StringIO

from pyinfra import host
from pyinfra.facts.files import File
from pyinfra.operations import apt, files, server, systemd
from pyinfra.facts.server import Arch

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())

app_ver = "v2.9.1"

arch = host.get_fact(Arch)
arch_suffix = "arm64" if arch == "aarch64" else "amd64"


files.directory(
    name="Ensure /opt/hy exists",
    path="/opt/hy",
)

files.download(
    name="Download Hysteria2 binary",
    src=f"https://download.hysteria.network/app/{app_ver}/hysteria-linux-{arch_suffix}",
    dest="/opt/hy/hysteria2",
    mode="755",
)

server.shell(
    name="Generate self-signed TLS cert",
    commands=[
        "openssl req -x509 -newkey rsa:3072 -keyout /opt/hy/server.key -out /opt/hy/server.crt -sha256 -days 3650 -nodes -subj '/CN=server'",
    ],
    _if=lambda: not host.get_fact(File, path="/opt/hy/server.key"),
)

files.file(
    name="Set TLS cert permission",
    path="/opt/hy/server.key",
    mode="644",
)

config_content = f"""listen: :{d.proxy.hysteria2_port}

tls:
  cert: /opt/hy/server.crt
  key: /opt/hy/server.key

auth:
  type: password
  password: {d.proxy.v2_uuid}
"""

config = files.put(
    name="Put hysteria2 config",
    src=StringIO(config_content),
    dest="/opt/hy/config.yml",
)

service_content = """[Unit]
Description=Hysteria Server Service
After=network.target

[Service]
Type=simple
DynamicUser=yes
ExecStart=/opt/hy/hysteria2 server --config /opt/hy/config.yml
WorkingDirectory=/opt/hy
Environment=HYSTERIA_LOG_LEVEL=debug
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
Restart=on-failure

[Install]
WantedBy=multi-user.target
"""

files.put(
    name="Put hysteria2 systemd service",
    src=StringIO(service_content),
    dest="/etc/systemd/system/hysteria2.service",
)

ipv4_register = (
    f'SELF_PUBLIC_IP=$(curl -4 -s https://ifconfig.me/ip)\n'
    f'if [ -n "$SELF_PUBLIC_IP" ]; then\n'
    f'  curl -G \'{d.proxy.sub_server}?token={d.proxy.reg_password}&id={host.name}_hy2&traffic={d.proxy.traffic}\' '
    f'--data-urlencode "subscription={{name: {host.name}_hy2, type: hysteria2, server: $SELF_PUBLIC_IP, port: {d.proxy.hysteria2_port}, password: {d.proxy.v2_uuid}, skip-cert-verify: true, client-fingerprint: chrome}}"\n'
    f'fi'
)

ipv6_register = ""
if d.proxy.ipv6_sub:
    ipv6_register = (
        f'\n\nSELF_PUBLIC_IPV6=$(curl -6 -s https://ifconfig.me/ip)\n'
        f'curl -G \'{d.proxy.sub_server}?token={d.proxy.reg_password}&id={host.name}_v6_hy2&traffic={d.proxy.traffic}\' '
        f'--data-urlencode "subscription={{name: {host.name}_v6_hy2, type: hysteria2, server: $SELF_PUBLIC_IPV6, port: {d.proxy.hysteria2_port}, password: {d.proxy.v2_uuid}, skip-cert-verify: true, client-fingerprint: chrome}}"'
    )

register_content = f"#!/bin/bash\n{ipv4_register}{ipv6_register}\n"

files.put(
    name="Put hysteria2 register script",
    src=StringIO(register_content),
    dest="/opt/hy/register.sh",
    mode="755",
)

server.crontab(
    name="Set up hysteria2 registration cron",
    command="/opt/hy/register.sh",
    minute="*/5",
)

systemd.service(
    name="Enable and start hysteria2",
    service="hysteria2",
    running=True,
    enabled=True,
    daemon_reload=config.changed,
    restarted=config.changed
)
