{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/chs1.nix
    ../../modules/dn42.nix
    ../../modules/ibgp-full-mesh.nix
    ../../modules/looking-glass.nix
    ../../modules/common.nix
    ../../modules/metrics.nix
  ];

  deployment = {
    targetHost = "35.211.99.153";
    targetUser = "root";
    tags = [ "gcp" "vps" ];
  };
  
  networking = {
    usePredictableInterfaceNames = false;
  };

  networking.networkmanager.enable = true;
  networking.hostName = "gcp-chs1";

  networking.wg-quick.interfaces.wg-warp = {
    autostart = true;
    address = [ "2606:4700:110:8eb4:6b54:7ffe:4c25:35fa/128" ];
    privateKey = secrets.warp.chs1.privateKey;
    mtu = 1280;
    peers = [
      {
        publicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
        allowedIPs = [ "::/0" ];
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