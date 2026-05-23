from io import StringIO

from pyinfra import host
from pyinfra.operations import apt, files, server, systemd

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())
m = d.misc

files.put(
    name="Add Caddy APT repository",
    src=StringIO("deb [trusted=yes] https://dl.cloudsmith.io/public/caddy/stable/debian bookworm main\n"),
    dest="/etc/apt/sources.list.d/caddy-stable.list",
)

apt.packages(
    name="Install Caddy",
    packages=["caddy"],
)


caddyfile_content = f"""sub.{m.domain} {{
    reverse_proxy 127.0.0.1:8002
}}

bot.{m.domain} {{
    reverse_proxy 127.0.0.1:8001
}}
"""

config = files.put(
    name="Upload Caddyfile",
    src=StringIO(caddyfile_content),
    dest="/etc/caddy/Caddyfile",
)

systemd.service(
    name="Enable and start Caddy",
    service="caddy",
    running=True,
    enabled=True,
    restarted=config.changed,
)
