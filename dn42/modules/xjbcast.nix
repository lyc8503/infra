{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.xjbcast;
in
{
  options.services.xjbcast = {
    enable = mkEnableOption "XJBCast Static HTTP Service";
    
    ipv4Address = mkOption {
      type = types.str;
      description = "IPv4 address to listen on";
    };

    ipv6Address = mkOption {
      type = types.str;
      description = "IPv6 address to listen on";
    };

    nodeName = mkOption {
      type = types.str;
      description = "Node name to display in the response";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 ];

    services.nginx = {
      enable = true;
      virtualHosts."xjbcast" = {
        listen = [
          { addr = cfg.ipv4Address; port = 80; }
          { addr = "[${cfg.ipv6Address}]"; port = 80; }
        ];
        locations."/" = {
          return = "200 'You are visiting XJBcast service hosted on AS4242420167.\\n\\nHostname: ${cfg.nodeName}\\nIPs: ${cfg.ipv4Address}, ${cfg.ipv6Address}\\n'";
          extraConfig = ''
            default_type text/plain;
          '';
        };
      };
    };
  };
}
