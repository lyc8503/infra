{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
  ];

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
}