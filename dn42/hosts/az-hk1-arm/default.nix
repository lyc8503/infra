{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/hkg1.nix
    ../../modules/common.nix
    ../../modules/dn42.nix
    ../../modules/ibgp-full-mesh.nix
    ../../modules/looking-glass.nix
    ../../modules/metrics.nix
    ../../modules/tcpdump.nix
    ../../modules/xray.nix
    ../../modules/hysteria.nix
  ];

  system.stateVersion = "25.11";
  networking.hostName = "az-hk-1-arm";

  networking = {
    usePredictableInterfaceNames = false;
  };

  networking.networkmanager.enable = true;

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
      subId = "az-hk1";
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
      subId = "az-hk1";
    };
  };

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  services.scx_horoscope.enable = false;

  deployment = {
    targetHost = secrets.az_hk1_arm_ip;
    targetUser = "root";
    tags = [ "azure" "vps" ];
  };
}