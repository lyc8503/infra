{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/lon1.nix
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
    ipv6 = secrets.tor.lon1.ipv6;
    nickname = secrets.tor.lon1.nickname;
    contactInfo = secrets.tor.contact;
    anchorIPv4 = "10.16.0.5";
    ipv4Gateway = "10.16.0.1";
    publicIPv4 = secrets.tor.lon1.ipv4;
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
      subId = "do_lon1";
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
      subId = "do_lon1";
    };
  };

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  deployment = {
    targetHost = "lon1.dn42.42420167.xyz";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };

  networking = {
    hostName = "do-lon1";
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [{
      address = "143.110.173.23";
      prefixLength = 20;
    }];
    interfaces.eth0.ipv6.addresses = [{
      address = "2a03:b0c0:1:e0::ed14:8001";
      prefixLength = 64;
    }];
    defaultGateway = {
      address = "143.110.160.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2a03:b0c0:1:e0::1";
      interface = "eth0";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };
}
