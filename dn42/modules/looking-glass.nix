{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dn42-looking-glass;
in
{
  options.services.dn42-looking-glass = {
    enable = mkEnableOption "DN42 Looking Glass";
    port = mkOption {
      type = types.int;
      default = 5000;
      description = "Port to listen on";
    };
    proxyPort = mkOption {
      type = types.int;
      default = 8000;
      description = "Port for the proxy to listen on";
    };
    servers = mkOption {
      type = types.listOf types.str;
      default = [ "localhost" ];
      description = "List of servers to query (prefixes)";
    };
    domain = mkOption {
      type = types.str;
      default = "";
      description = "Domain suffix for servers";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.bird-lg-proxy = {
      description = "Bird Looking Glass Proxy";
      after = [ "bird.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.bird-lg}/bin/proxy --bird /run/bird/bird.ctl --listen 0.0.0.0:${toString cfg.proxyPort}";
        Restart = "always";
        User = "root";
      };
    };

    systemd.services.bird-lg-frontend = {
      description = "Bird Looking Glass Frontend";
      after = [ "bird-lg-proxy.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.bird-lg}/bin/frontend --servers ${concatStringsSep "," cfg.servers} --domain ${cfg.domain} --proxy-port ${toString cfg.proxyPort} --listen 0.0.0.0:${toString cfg.port}";
        Restart = "always";
        User = "nobody";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port cfg.proxyPort ];
  };
}
