{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
    ../../modules/looking-glass.nix
  ];

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
    asn = 4242420167;
    ipv4.routerId = "172.20.42.225";
    ipv4.network = "172.20.42.224/27";
    ipv6.routerId = "fd00:1100:8503::2";
    ipv6.network = "fd00:1100:8503::/48";
  };

  networking.dn42.peers.ams1 = {
    asn = 4242420167;
    listenPort = 10001;
    privateKey = lib.trim (builtins.readFile ../../secrets/do-sfo1.key);
    publicKey = "8X4sDGOx0koca/fJw/OOlUycgV5HMYER0QTkkAHZ6RE=";
    endpoint = "ams1.dn42.42420167.xyz:10002";
    ipv6 = {
      local = "fe80::2";
      remote = "fe80::1";
    };
  };

  networking.dn42.peers.sgp1 = {
    asn = 4242420167;
    listenPort = 10003;
    privateKey = lib.trim (builtins.readFile ../../secrets/do-sfo1.key);
    publicKey = "OUjT7QCteL40MpZJeAh1HEMSH7Uu0g0vBIIjShRQVDc=";
    endpoint = "sgp1.dn42.42420167.xyz:10002";
    ipv6 = {
      local = "fe80::2";
      remote = "fe80::3";
    };
  };
}