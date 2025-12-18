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
    targetHost = "sgp1.dn42.42420167.xyz";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

  system.stateVersion = "25.11";

  networking = {
    hostName = "do-sgp1";
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "167.99.65.156";
      prefixLength = 20;
    }];
    interfaces.eth0.ipv6.addresses = [{
      address = "2400:6180:0:d2:0:2:7490:d000";
      prefixLength = 64;
    }];
    defaultGateway = {
      address = "167.99.64.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2400:6180:0:d2::1";
      interface = "eth0";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.routerId = "172.20.42.224";
    ipv4.network = "172.20.42.224/27";
    ipv6.routerId = "fd00:1100:8503::1";
    ipv6.network = "fd00:1100:8503::/48";
  };

  networking.dn42.peers.ams1 = {
    asn = 4242420167;
    listenPort = 10001;
    privateKey = secrets.key_do_sgp1;
    publicKey = secrets.key_do_ams1_pub;
    endpoint = "ams1.dn42.42420167.xyz:10003";
    ipv6 = {
      local = "fe80::3";
      remote = "fe80::1";
    };
  };

  networking.dn42.peers.sfo1 = {
    asn = 4242420167;
    listenPort = 10002;
    privateKey = secrets.key_do_sgp1;
    publicKey = secrets.key_do_sfo1_pub;
    endpoint = "sfo1.dn42.42420167.xyz:10003";
    ipv6 = {
      local = "fe80::3";
      remote = "fe80::2";
    };
  };

  networking.dn42.peers."3914" = {
    asn = 4242423914;
    listenPort = 23914;
    privateKey = secrets.key_do_sgp1;
    publicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
    endpoint = "hk1.g-load.eu:20167";
    
    ipv6 = {
      local = "fe80::ade1";
      remote = "fe80::ade0";
    };
    
    # ipv4 = {
    #   local = "172.20.42.224";
    #   remote = "172.20.53.105";
    # };
  };

  networking.dn42.peers."2034" = {
    asn = 4242422034;
    listenPort = 22034;
    privateKey = secrets.key_do_sgp1;
    publicKey = "Zl72hWVO9Ib3ylYqKpDCEq8VyiJjY0WDhXP+vX+CzFs=";
    endpoint = "v1.932.moe:20167";
    ipv6 = {
      local = "fe80::1067";
      remote = "fe80::2034";
    };

    # ipv4 = {
    #   local = "172.20.42.224";
    #   remote = "172.21.104.33";
    # };
  };

  networking.dn42.peers."2279" = {
    asn = 4242422279;
    listenPort = 22279;
    privateKey = secrets.key_do_sgp1;
    publicKey = "Yu5PP+dKWqFCWSOqzEd2d3YGPZDOs7bgxQfZiNJjJH4=";
    endpoint = "sg-sin1.bb.mhr.hk:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::2279";
    };
  };
}