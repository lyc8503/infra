"""Shared utility to ensure Docker is installed on Debian targets."""
from io import StringIO

from pyinfra import host
from pyinfra.operations import files, server
from pyinfra.facts.files import File


def ensure_docker():
    """Install Docker CE and Compose plugin if not already present."""
    files.put(
        name="Add Docker APT repository",
        src=StringIO("deb [trusted=yes] https://download.docker.com/linux/debian bookworm stable\n"),
        dest="/etc/apt/sources.list.d/docker.list",
    )

    server.shell(
        name="Install Docker and Compose",
        commands=[
            "apt-get update -qq",
            "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || true",
        ],
        _if=lambda: not host.get_fact(File, path="/usr/bin/docker"),
    )
