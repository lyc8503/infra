from io import StringIO

from pyinfra import host
from pyinfra.operations import files, server, systemd
from pyinfra.facts.server import Arch
from pyinfra.facts.files import File

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())

FRP_VER = "0.69.0"

arch = host.get_fact(Arch)
frp_arch = "arm64" if arch == "aarch64" else "amd64"

files.directory(
    name="Ensure /opt/frp exists",
    path="/opt/frp",
)

server.shell(
    name="Download and extract frp",
    commands=[
        f"curl -L -o /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/download/v{FRP_VER}/frp_{FRP_VER}_linux_{frp_arch}.tar.gz",
        f"tar xzf /tmp/frp.tar.gz -C /opt/frp --strip-components=1",
    ],
    _if=lambda: not host.get_fact(File, path="/opt/frp/frps"),
)

frps_config = f"""bindPort = 7000
auth.token = "{d.frps_token}"
"""

frps_conf = files.put(
    name="Put frps config",
    src=StringIO(frps_config),
    dest="/opt/frp/frps.toml",
)

frps_service = """[Unit]
Description=FRP Server
After=network.target

[Service]
ExecStart=/opt/frp/frps -c /opt/frp/frps.toml
Restart=on-failure

[Install]
WantedBy=multi-user.target
"""

files.put(
    name="Put frps systemd service",
    src=StringIO(frps_service),
    dest="/etc/systemd/system/frps.service",
)

systemd.service(
    name="Enable and start frps",
    service="frps",
    running=True,
    enabled=True,
    restarted=frps_conf.changed,
    daemon_reload=True,
)