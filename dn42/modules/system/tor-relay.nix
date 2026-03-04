{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tor-relay;
in
{
  options.services.tor-relay = {
    enable = mkEnableOption "Tor Relay Service";

    nickname = mkOption {
      type = types.str;
      description = "Nickname for the Tor Relay";
    };

    contactInfo = mkOption {
      type = types.str;
      description = "Contact Info for the Tor Relay";
    };

    monthlyLimitGB = mkOption {
      type = types.int;
      default = 750;
      description = "Monthly traffic limit in GBytes, split into daily accounting.";
    };
  };

  config = mkIf cfg.enable {
    services.tor = {
      enable = true;
      relay = {
        enable = true;
        role = "relay";
      };
      settings = {
        # Listen on all interfaces; IP address management is handled externally
        # by the anchor-routing service (anchorIPv4 + extraIPv6).
        ORPort = [
          { addr = "0.0.0.0"; port = 7443; }
          { addr = "[::]"; port = 7443; }
        ];

        AccountingMax = "${toString (cfg.monthlyLimitGB * 1024 / 30)} MBytes";
        AccountingStart = "day 00:00";

        Nickname = cfg.nickname;
        ContactInfo = cfg.contactInfo;

        ExitRelay = false;
      };
    };
  };
}
