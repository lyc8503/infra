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
    ../../modules/xray.nix
    ../../modules/hysteria.nix
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

  services.my-xray = {
    enable = true;
    uuid = secrets.proxy.uuid;
    visionPort = 23389;
    realityDest = "software.download.prss.microsoft.com:443";
    realityPrivateKey = secrets.proxy.reality_sk;
    realityShortIds = secrets.proxy.short_ids;
    registration = {
      enable = true;
      subServer = secrets.proxy.sub_server;
      regPassword = secrets.proxy.reg_password;
      subId = "do_tor1";
      realityPublicKey = secrets.proxy.reality_pk;
    };
  };

  services.my-hysteria = {
    enable = true;
    port = 61145;
    password = secrets.proxy.uuid;
    registration = {
      enable = true;
      subServer = secrets.proxy.sub_server;
      regPassword = secrets.proxy.reg_password;
      subId = "do_tor1";
    };
  };

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
      address = "142.93.150.243";
      prefixLength = 20;
    }];
    interfaces.eth0.ipv6.addresses = [{
      address = "2604:a880:cad:d0:0:1:32c7:6001";
      prefixLength = 64;
    }];
    defaultGateway = {
      address = "142.93.144.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2604:a880:cad:d0::1";
      interface = "eth0";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
}
