{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/sfo1.nix
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
      subId = "do-sfo1";
      realityPublicKey = secrets.proxy.reality_pk;
      traffic = 1000;
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
      subId = "do-sfo1";
      traffic = 1000;
    };
  };

  services.tor-relay = {
    enable = true;
    ipv6 = secrets.tor.sfo1.ipv6;
    nickname = secrets.tor.sfo1.nickname;
    contactInfo = secrets.tor.contact;
    anchorIPv4 = "10.48.0.5";
    ipv4Gateway = "10.48.0.1";
    publicIPv4 = secrets.tor.sfo1.ipv4;
    monthlyLimitGB = 200;
  };

  system.stateVersion = "25.11";

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  deployment = {
    targetHost = "64.227.99.106";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

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