from pyinfra import host
from pyinfra.operations import apt, server

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