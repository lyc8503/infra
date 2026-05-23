from io import StringIO

from pyinfra import host
from pyinfra.operations import apt, files, server, systemd

from dacite import from_dict
from schema import HostData

d = from_dict(HostData, host.data.dict())
m = d.misc

COMPOSE_DIR = "/opt/misc-docker"


files.put(
    name="Add Docker APT repository",
    src=StringIO("deb [trusted=yes] https://download.docker.com/linux/debian bookworm stable\n"),
    dest="/etc/apt/sources.list.d/docker.list",
)

apt.packages(
    name="Install Docker and Compose",
    packages=["docker-ce", "docker-ce-cli", "containerd.io", "docker-compose-plugin"],
    update=True
)

# 2. Create compose directory and rsync source files
files.directory(
    name=f"Ensure {COMPOSE_DIR} exists",
    path=COMPOSE_DIR,
)

files.rsync(
    name="Upload container source files",
    src="files/containers/",
    dest=f"{COMPOSE_DIR}/",
)

# 3. Generate and upload .env file
env_content = f"""ADMIN_PASSWORD={m.sub_admin_password}
REG_PASSWORD={m.sub_reg_password}
BOT_TOKEN={m.tgbot_token}
CHAT_ID={m.tgbot_chat_id}
PUSH_KEY={m.tgbot_push_key}
SELF_URL={m.tgbot_self_url}
SECRET_TOKEN={m.tgbot_secret_token}
TOKEN={m.tgrss_token}
MANAGER={m.tgrss_manager}
LOKI_TOKEN={m.log_forward_loki_token}
"""

files.put(
    name="Upload .env file",
    src=StringIO(env_content),
    dest=f"{COMPOSE_DIR}/.env",
)

# 4. Generate and upload compose.yaml
compose_content = """services:
  sub:
    build: ./sub
    restart: unless-stopped
    ports:
      - "127.0.0.1:8002:8002"
    environment:
      - ADMIN_PASSWORD
      - REG_PASSWORD

  tgbot:
    build: ./TGBot
    restart: unless-stopped
    ports:
      - "127.0.0.1:8001:8000"
    environment:
      - BOT_TOKEN
      - CHAT_ID
      - PUSH_KEY
      - SELF_URL
      - SECRET_TOKEN
    volumes:
      - /opt/nju.txt:/app/nju.txt

  tgrss:
    image: rongronggg9/rss-to-telegram:dev
    restart: unless-stopped
    volumes:
      - /opt/tgrss:/app/config
    environment:
      - TOKEN
      - MANAGER

  log_forward:
    build: ./log_forward
    restart: unless-stopped
    environment:
      - LOKI_TOKEN
      - PUSH_KEY
"""

files.put(
    name="Upload compose.yaml",
    src=StringIO(compose_content),
    dest=f"{COMPOSE_DIR}/compose.yaml",
)

# 5. Deploy with docker compose
server.shell(
    name="Deploy misc containers",
    commands=[
        f"cd {COMPOSE_DIR} && docker compose up -d --build --remove-orphans",
    ],
)
