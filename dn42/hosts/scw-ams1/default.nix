{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/ams1.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
    ../../modules/ibgp-full-mesh.nix
    ../../modules/metrics.nix
    ../../modules/looking-glass.nix
    ../../modules/xjbcast.nix
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
      subId = "scw-ams";
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
      subId = "scw-ams";
      traffic = 1000;
    };
  };

  deployment = {
    targetHost = "2001:bc8:1640:4f16:f5bf:e8bf:fd1d:e65a";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };
  
  networking = {
    usePredictableInterfaceNames = false;
  };

  networking.networkmanager.enable = true;
  networking.hostName = "scw-ams1";
  
  networking.wg-quick.interfaces.wg-warp = {
    autostart = true;
    address = [ "172.16.0.2/32" ];
    privateKey = secrets.warp.ams1.privateKey;
    mtu = 1280;
    peers = [
      {
        publicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "engage.cloudflareclient.com:2408";
        persistentKeepalive = 25;
      }
    ];
  };

  system.stateVersion = "25.11";

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };
}