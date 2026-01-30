{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.frps;
  secrets = import ../../secrets.nix;
in
{
  options.services.frps = {
    enable = mkEnableOption "FRP Server Service";
  };

  config = mkIf cfg.enable {
    services.frp = {
      enable = true;
      role = "server";
      settings = {
        bindPort = 7000;
        auth.token = secrets.frp_token;
      };
    };

    networking.firewall.allowedTCPPorts = [ 7000 ];
  };
}
