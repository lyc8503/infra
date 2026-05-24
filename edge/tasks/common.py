from io import StringIO

from pyinfra import host
from pyinfra.operations import apt, server, files, systemd

apt.packages(
    name="Install common apt packages",
    packages=[
        "python3", "python3-dev", "python3-pip",
        "git", "curl", "wget", "gpg", "unzip",
        "vim", "htop", "btop", "tmux", "jq",
        "tcpdump", "mtr-tiny", "iperf3", "dnsutils",
        "rsync"
    ],
)

server.hostname(
    name="Set hostname",
    hostname=host.name,
)

server.sysctl(
    name="Enable BBR congestion control",
    key="net.ipv4.tcp_congestion_control",
    value="bbr",
    persist=True,
)

server.sysctl(
    name="Enable FQ qdisc",
    key="net.core.default_qdisc",
    value="fq",
    persist=True,
)

apt.packages(
    name="Install zram tools",
    packages=[
        "zram-tools"
    ],
)

zram_config = files.put(
    name="Set zram config",
    src=StringIO("ALGO=lz4\nPERCENT=150\nPRIORITY=100\n"),
    dest="/etc/default/zramswap",
)

systemd.service(
    name="Enable and start zram",
    service="zramswap",
    running=True,
    enabled=True,
    restarted=zram_config.changed,
)
