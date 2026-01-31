{ config, pkgs, lib, ... }:

let
  nodeBuilder = import ../../lib/node-builder.nix { inherit lib pkgs; };
  autoConfig = nodeBuilder.mkProfile "do-fra1";
  nodeRegistry = nodeBuilder.nodeRegistry;
  node = nodeRegistry.nodes.do-fra1;
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
        address = "46.101.112.1";
        interface = "eth0";
      };
      defaultGateway6 = {
        address = "2a03:b0c0:3:f0::1";
        interface = "eth0";
      };
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
    }
  ];
}
