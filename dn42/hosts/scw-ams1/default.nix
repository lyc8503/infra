{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/metrics.nix
  ];

  deployment = {
    targetHost = "2001:bc8:1640:4f16:f5bf:e8bf:fd1d:e65a";
    targetUser = "root";
    tags = [ "digitalocean" "vps" ];
  };
  
  networking = {
    usePredictableInterfaceNames = false;
  };

  networking.networkmanager.enable = true;
  networking.hostName = "scw-ams1";
  
  system.stateVersion = "25.11";

  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };
}