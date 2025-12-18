{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
    ../../modules/looking-glass.nix
    ../../modules/metrics.nix
    ../../modules/knot-dns.nix
    ../../modules/zones.nix
  ];

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  services.dn42-looking-glass = {
    enable = true;
    servers = [ "ams1" "sfo1" "sgp1" ];
    domain = "dn42.42420167.xyz";
  };

  deployment = {
    targetHost = "sfo1.dn42.42420167.xyz";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

  system.stateVersion = "25.11";

  networking = {
    hostName = "do-sfo1";
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "64.227.99.106";
      prefixLength = 20;
    }];
    interfaces.eth0.ipv6.addresses = [{
      address = "2604:a880:4:1d0:0:1:4500:1000";
      prefixLength = 64;
    }];
    defaultGateway = {
      address = "64.227.96.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2604:a880:4:1d0::1";
      interface = "eth0";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.routerId = "172.20.42.225";
    ipv4.network = "172.20.42.224/27";
    ipv6.routerId = "fd00:1100:8503::2";
    ipv6.network = "fd00:1100:8503::/48";
  };

  networking.dn42.peers.ams1 = {
    asn = 4242420167;
    listenPort = 10001;
    privateKey = secrets.key_do_sfo1;
    publicKey = secrets.key_do_ams1_pub;
    endpoint = "ams1.dn42.42420167.xyz:10002";
    ipv6 = {
      local = "fe80::2";
      remote = "fe80::1";
    };
  };

  networking.dn42.peers.sgp1 = {
    asn = 4242420167;
    listenPort = 10003;
    privateKey = secrets.key_do_sfo1;
    publicKey = secrets.key_do_sgp1_pub;
    endpoint = "sgp1.dn42.42420167.xyz:10002";
    ipv6 = {
      local = "fe80::2";
      remote = "fe80::3";
    };
  };

  networking.dn42.peers."3377" = {
    asn = 4242423377;
    listenPort = 23377;
    privateKey = secrets.key_do_sfo1;
    publicKey = "Xzt9UrH2moj84QSH0jsw8Zj+jwXwdBLpApe4hHyfnAw=";
    endpoint = "v4.los1-us.peer.dn42.leziblog.com:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::3377";
    };
  };

  networking.dn42.peers."1117" = {
    asn = 4242421117;
    listenPort = 21117;
    privateKey = secrets.key_do_sfo1;
    publicKey = "PW/+rv0B8e4tUJ9j1TWscx1sl36WwhPh9adEqoM7Jic=";
    endpoint = "us01.dn42.yuyuko.com:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1117";
    };
  };
}