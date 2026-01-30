{ config, pkgs, lib, ... }:

let
  nodeBuilder = import ../../lib/node-builder.nix { inherit lib pkgs; };
  autoConfig = nodeBuilder.mkProfile "gcp-chs1";
  secrets = import ../../secrets.nix;
in
{
  imports = [ ./hardware.nix ./peers.nix ] ++ autoConfig.imports;

  inherit (autoConfig) deployment system services;

  networking = lib.mkMerge [
    autoConfig.networking
    {
      wg-quick.interfaces.wg-warp = {
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
    }
  ];
}
