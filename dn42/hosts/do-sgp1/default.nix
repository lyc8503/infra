{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/sgp1.nix
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
    ipv6 = secrets.tor.sgp1.ipv6;
    nickname = secrets.tor.sgp1.nickname;
    contactInfo = secrets.tor.contact;
    ipv4Gateway = "10.15.0.1";
    anchorIPv4 = "10.15.0.5";
    publicIPv4 = secrets.tor.sgp1.ipv4;
  };
  
  system.stateVersion = "25.11";

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  deployment = {
    targetHost = "sgp1.dn42.42420167.xyz";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

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

}