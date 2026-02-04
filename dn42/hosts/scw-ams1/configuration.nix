{ config, pkgs, lib, ... }:

let
  nodeBuilder = import ../../lib/node-builder.nix { inherit lib pkgs; };
  autoConfig = nodeBuilder.mkProfile "scw-ams1";
  secrets = import ../../secrets.nix;
in
{
  imports = [ 
    ./hardware.nix 
    ./peers.nix
  ] ++ autoConfig.imports;

  inherit (autoConfig) deployment system;

  services = lib.mkMerge [
    autoConfig.services
    {
      snowflake-proxy.enable = true;
    }
  ];

  networking = lib.mkMerge [
    autoConfig.networking
    {
      wg-quick.interfaces.wg-warp = {
        autostart = true;
        address = [ "172.16.0.2/32" ];
        privateKey = secrets.warp.ams1.privateKey;
        mtu = 1280;
        peers = [
          {
            publicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "[2606:4700:d0::a29f:c001]:2408";
            persistentKeepalive = 25;
          }
        ];
      };
    }
  ];
}
