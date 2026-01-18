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
  system.stateVersion = "25.11";

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };
}