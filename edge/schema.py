from dataclasses import dataclass, field


@dataclass
class ProxyConfig:
    hysteria2_port: int = 61145
    vmess_port: int = 23390
    traffic: int = 100
    ipv6_sub: bool = False
    v2_uuid: str = ""
    sub_server: str = ""
    reg_password: str = ""


@dataclass
class MiscConfig:
    domain: str = ""
    endpoint: str = ""
    sub_admin_password: str = ""
    sub_reg_password: str = ""
    tgbot_token: str = ""
    tgbot_chat_id: str = ""
    tgbot_push_key: str = ""
    tgbot_self_url: str = ""
    tgbot_secret_token: str = ""
    tgrss_token: str = ""
    tgrss_manager: str = ""
    log_forward_loki_token: str = ""


@dataclass
class DN42Peer:
    asn: int = 0
    listen_port: int = 0
    private_key: str = ""
    public_key: str = ""
    endpoint: str = ""
    ipv6_local: str = ""
    ipv6_remote: str = ""
    ipv4_local: str = ""
    ipv4_remote: str = ""
    mtu: int | None = None


@dataclass
class DNetConfig:
    ip: str = ""
    netmask: str = ""
    cidr: str = ""
    external_interface: str = "eth0"


@dataclass
class DN42Config:
    asn: int = 0
    ipv4_addresses: list[str] = field(default_factory=list)
    ipv4_dnet_address: str = ""
    ipv4_networks: list[str] = field(default_factory=list)
    ipv6_addresses: list[str] = field(default_factory=list)
    ipv6_networks: list[str] = field(default_factory=list)
    private_key: str = ""
    ebgp_peers: dict[str, DN42Peer] = field(default_factory=dict)
    dnet: DNetConfig | None = None


@dataclass
class HostData:
    ssh_hostname: str = ""
    ssh_port: int = 22
    ssh_user: str = "root"

    push_endpoint: str | None = None
    loki_endpoint: str | None = None

    proxy: ProxyConfig | None = None
    misc: MiscConfig | None = None
    dn42: DN42Config | None = None