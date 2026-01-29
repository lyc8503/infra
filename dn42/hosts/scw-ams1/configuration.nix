{ config, pkgs, lib, ... }:

let
  nodeBuilder = import ../../lib/node-builder.nix { inherit lib pkgs; };
  autoConfig = nodeBuilder.mkProfile "scw-ams1";
in
{
  imports = [ ./hardware.nix ./peers.nix ] ++ autoConfig.imports;

  inherit (autoConfig) deployment system networking services;
}
