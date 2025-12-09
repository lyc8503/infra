{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  deployment = {
    targetHost = "167.99.65.156";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

  system.stateVersion = "25.11";

  networking = {
    hostName = "do-sg1";
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "167.99.65.156";
      prefixLength = 20;
    }];
    defaultGateway = {
      address = "167.99.64.1";
      interface = "eth0";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
}