{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
  ];

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
}