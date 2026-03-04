{ config, pkgs, lib, ... }:

let
  nodeBuilder = import ../../lib/node-builder.nix { inherit lib pkgs; };
  autoConfig = nodeBuilder.mkProfile "do-sfo1";
  nodeRegistry = nodeBuilder.nodeRegistry;
  node = nodeRegistry.nodes.do-sfo1;
in
{
  imports = [ ./hardware.nix ./peers.nix ] ++ autoConfig.imports;

  inherit (autoConfig) deployment system services;

  # Host-specific networking configuration
  networking = lib.mkMerge [
    autoConfig.networking
    {
      interfaces.eth0.ipv4.addresses = [{
        address = node.publicIpv4;
        prefixLength = 20;
      }];
      interfaces.eth0.ipv6.addresses = [{
        address = node.publicIpv6;
        prefixLength = 64;
      }];
      defaultGateway = {
        address = "64.23.240.1";
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
