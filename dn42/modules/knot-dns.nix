{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dn42-dns;
in
{
  options.services.dn42-dns = {
    enable = mkEnableOption "DN42 Authoritative DNS";
    
    domain = mkOption {
      type = types.str;
      description = "The domain name for the zone.";
    };

    zoneFile = mkOption {
      type = types.path;
      description = "Path to the zone file.";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.knot = {
      enable = true;
      settings = {
        server = {
          listen = [ "0.0.0.0@53" "::@53" ];
        };
        zone = {
          "${cfg.domain}" = {
            file = "${cfg.zoneFile}";
          };
        };
      };
    };
  };
}
