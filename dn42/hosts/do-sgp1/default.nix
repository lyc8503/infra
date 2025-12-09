{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
  ];

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

  networking.dn42.peers."3914" = {
    asn = 4242423914;
    listenPort = 23914;
    privateKey = lib.trim (builtins.readFile ../../secrets/3914.key);
    publicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
    endpoint = "hk1.g-load.eu:20167";
    
    ipv6 = {
      local = "fe80::ade1";
      remote = "fe80::ade0";
    };
    
    ipv4 = {
      local = "172.20.42.224";
      remote = "172.20.53.105";
    };
  };
}