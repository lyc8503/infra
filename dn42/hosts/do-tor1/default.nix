{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/tor1.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
    ../../modules/ibgp-full-mesh.nix
    ../../modules/looking-glass.nix
    ../../modules/metrics.nix
    ../../modules/tcpdump.nix
    ../../modules/tor-relay.nix
  ];

  services.tor-relay = {
    enable = true;
    ipv6 = secrets.tor.tor1.ipv6;
    nickname = secrets.tor.tor1.nickname;
    contactInfo = secrets.tor.contact;
    anchorIPv4 = "10.20.0.5";
    ipv4Gateway = "10.20.0.1";
    publicIPv4 = secrets.tor.tor1.ipv4;
  };

  system.stateVersion = "25.11";

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  deployment = {
    targetHost = "tor1.dn42.42420167.xyz";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

  networking = {
    hostName = "do-tor1";
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "159.203.11.66";
      prefixLength = 20;
    }];
    interfaces.eth0.ipv6.addresses = [{
      address = "2604:a880:cad:d0:0:1:321a:4001";
      prefixLength = 64;
    }];
    defaultGateway = {
      address = "159.203.0.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2604:a880:cad:d0::1";
      interface = "eth0";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
}
