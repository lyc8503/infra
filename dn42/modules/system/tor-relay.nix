{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tor-relay;
  eth0Ipv4Addrs = config.networking.interfaces.eth0.ipv4.addresses or [ ];
  eth0Ipv6Addrs = config.networking.interfaces.eth0.ipv6.addresses or [ ];
  publicIpv4 = if eth0Ipv4Addrs != [ ] then (head eth0Ipv4Addrs).address else null;
  publicIpv6 = if eth0Ipv6Addrs != [ ] then (head eth0Ipv6Addrs).address else null;
  orPorts =
    (optional (publicIpv4 != null) { addr = publicIpv4; port = 7443; })
    ++ (optional (publicIpv6 != null) { addr = "[${publicIpv6}]"; port = 7443; });
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
        # Bind only to configured public addresses on eth0.
        ORPort = if orPorts != [ ] then orPorts else [
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
