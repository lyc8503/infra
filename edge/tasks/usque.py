from io import StringIO

from pyinfra import host
from pyinfra.operations import files, server, systemd
from pyinfra.facts.files import File
from pyinfra.facts.server import Arch

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())

USQUE_VER = "4.2.1"
USQUE_DIR = "/opt/usque"
USQUE_BIN = f"{USQUE_DIR}/usque"
USQUE_CONFIG = f"{USQUE_DIR}/config.json"
USQUE_SOCKS_PORT = 10800

arch = host.get_fact(Arch)
if arch == "aarch64":
    usque_arch = "arm64"
elif arch == "armv7l":
    usque_arch = "armv7"
else:
    usque_arch = "amd64"

files.directory(
    name="Ensure /opt/usque exists",
    path=USQUE_DIR,
)

server.shell(
    name="Download and extract usque",
    commands=[
        f"curl -L -o /tmp/usque.zip https://github.com/Diniboy1123/usque/releases/download/v{USQUE_VER}/usque_{USQUE_VER}_linux_{usque_arch}.zip",
        f"unzip -o /tmp/usque.zip -d {USQUE_DIR}",
    ],
    _if=lambda: not host.get_fact(File, path=USQUE_BIN),
)

# `register` creates a fresh WARP account and writes a working config.json.
# Cloudflare rate-limits registrations, so only register when no config exists yet.
server.shell(
    name="Register usque WARP account",
    commands=[
        f"cd {USQUE_DIR} && ./usque register -a -n {host.name} -c {USQUE_CONFIG}",
    ],
    _if=lambda: not host.get_fact(File, path=USQUE_CONFIG),
)

service_content = """[Unit]
Description=Usque MASQUE WARP proxy (HTTP/2)
After=network.target

[Service]
WorkingDirectory=/opt/usque
ExecStart=/opt/usque/usque socks --http2 -b 127.0.0.1 -p 10800 --http2 -c /opt/usque/config.json
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
"""

files.put(
    name="Put usque systemd service",
    src=StringIO(service_content),
    dest="/etc/systemd/system/usque.service",
)

systemd.service(
    name="Enable and start usque",
    service="usque",
    running=True,
    enabled=True,
    daemon_reload=True,
)
