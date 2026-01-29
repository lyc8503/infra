{ config, pkgs, lib, ... }:

let
  nodeBuilder = import ../../lib/node-builder.nix { inherit lib pkgs; };
  autoConfig = nodeBuilder.mkProfile "do-sfo1";
in
{
  imports = [ ./hardware.nix ./peers.nix ] ++ autoConfig.imports;

  inherit (autoConfig) deployment system services;

  # Host-specific networking configuration
  networking = lib.mkMerge [
    autoConfig.networking
    {
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
    }
  ];
}
