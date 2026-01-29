{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  # Only external DN42 peers - DN42 base config is auto-generated
  # Note: az-sg1 currently has no external peers
}
