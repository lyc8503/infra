{ config, pkgs, lib, ... }:

let
  nodeBuilder = import ../../lib/node-builder.nix { inherit lib pkgs; };
  autoConfig = nodeBuilder.mkProfile "az-sg1";
in
{
  imports = [ ./hardware.nix ./peers.nix ] ++ autoConfig.imports;

  inherit (autoConfig) deployment system services networking;
}