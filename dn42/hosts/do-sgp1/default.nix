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

  networking.dn42 = {
    asn = 4242420167;
    ipv4.routerId = "172.20.42.224";
    ipv4.network = "172.20.42.224/27";
    ipv6.routerId = "fd00:1100:8503::1";
    ipv6.network = "fd00:1100:8503::/48";
  };

  networking.dn42.peers.ams1 = {
    asn = 4242420167;
    listenPort = 10001;
    privateKey = lib.trim (builtins.readFile ../../secrets/do-sgp1.key);
    publicKey = "8X4sDGOx0koca/fJw/OOlUycgV5HMYER0QTkkAHZ6RE=";
    endpoint = "ams1.dn42.42420167.xyz:10003";
    ipv6 = {
      local = "fe80::3";
      remote = "fe80::1";
    };
  };

  networking.dn42.peers.sfo1 = {
    asn = 4242420167;
    listenPort = 10002;
    privateKey = lib.trim (builtins.readFile ../../secrets/do-sgp1.key);
    publicKey = "aOfobLo+vPiOHzA98aOLWfZs1ROw5w+H7H5RCp4qbxg=";
    endpoint = "sfo1.dn42.42420167.xyz:10003";
    ipv6 = {
      local = "fe80::3";
      remote = "fe80::2";
    };
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

  networking.dn42.peers."2034" = {
    asn = 4242422034;
    listenPort = 22034;
    privateKey = lib.trim (builtins.readFile ../../secrets/2034.key);
    publicKey = "Zl72hWVO9Ib3ylYqKpDCEq8VyiJjY0WDhXP+vX+CzFs=";
    endpoint = "v1.932.moe:20167";
    ipv6 = {
      local = "fe80::1067";
      remote = "fe80::2034";
    };
    ipv4 = {
      local = "172.20.42.224";
      remote = "172.21.104.33";
    };
  };
}