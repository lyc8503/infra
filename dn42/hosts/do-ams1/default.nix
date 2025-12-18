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
    targetHost = "ams1.dn42.42420167.xyz";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

  system.stateVersion = "25.11";

  networking = {
    hostName = "do-ams1";
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "165.22.195.57";
      prefixLength = 20;
    }];
    interfaces.eth0.ipv6.addresses = [{
      address = "2a03:b0c0:2:f0:0:1:1760:e001";
      prefixLength = 64;
    }];
    defaultGateway = {
      address = "165.22.192.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2a03:b0c0:2:f0::1";
      interface = "eth0";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  networking.dn42 = {
    asn = 4242420167;
    ipv4.routerId = "172.20.42.226";
    ipv4.network = "172.20.42.224/27";
    ipv6.routerId = "fd00:1100:8503::3";
    ipv6.network = "fd00:1100:8503::/48";
  };

  networking.dn42.peers.sfo1 = {
    asn = 4242420167;
    listenPort = 10002;
    privateKey = secrets.key_do_ams1;
    publicKey = secrets.key_do_sfo1_pub;
    endpoint = "sfo1.dn42.42420167.xyz:10001";
    ipv6 = {
      local = "fe80::1";
      remote = "fe80::2";
    };
  };

  networking.dn42.peers.sgp1 = {
    asn = 4242420167;
    listenPort = 10003;
    privateKey = secrets.key_do_ams1;
    publicKey = secrets.key_do_sgp1_pub;
    endpoint = "sgp1.dn42.42420167.xyz:10001";
    ipv6 = {
      local = "fe80::1";
      remote = "fe80::3";
    };
  };

  networking.dn42.peers."1888" = {
    asn = 4242421888;
    listenPort = 21888;
    privateKey = secrets.key_do_ams1;
    publicKey = "k9F2akSTkbA/GiO59PNW/v0D65ioMYD4P1DqeKSL3FM=";
    endpoint = "de1.dn42.ni.sb:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1888";
    };
  };
}