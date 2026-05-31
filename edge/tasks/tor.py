from io import StringIO

from pyinfra import host
from pyinfra.operations import apt, files, server, systemd

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())

files.put(
    name="Add Tor APT repo",
    src=StringIO("deb [trusted=yes] https://deb.torproject.org/torproject.org bookworm main\n"),
    dest="/etc/apt/sources.list.d/tor.list",
)

apt.packages(
    name="Install tor",
    packages=["tor"],
    update=True,
)

nickname = d.tor_relay.nickname
contact = d.tor_relay.contact_info
monthly_limit_gb = d.tor_relay.monthly_limit_gb

# AccountingMax = monthlyLimitGB * 1024 / 30 MBytes per day
accounting_max = monthly_limit_gb * 1024 // 30

# Detect public IPs from the host
tor_config = f"""Nickname {nickname}
ContactInfo {contact}
ORPort 0.0.0.0:7443
ExitRelay 0
AccountingMax {accounting_max} MBytes
AccountingStart day 00:00
"""

tor_conf = files.put(
    name="Put tor config",
    src=StringIO(tor_config),
    dest="/etc/tor/torrc",
)

systemd.service(
    name="Enable and start tor",
    service="tor",
    running=True,
    enabled=True,
    restarted=tor_conf.changed,
)
