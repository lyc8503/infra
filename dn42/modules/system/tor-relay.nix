{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tor-relay;
in
{
  options.services.tor-relay = {
    enable = mkEnableOption "Tor Relay Service";
    ipv6 = mkOption { type = types.str; description = "Extra IPv6 address for Tor"; };
    nickname = mkOption { 
      type = types.str; 
      description = "Nickname for the Tor Relay";
    };
    contactInfo = mkOption {
      type = types.str;
      description = "Contact Info for the Tor Relay";
    };
    ipv4Gateway = mkOption {
      type = types.str;
      description = "Gateway for the anchor IPv4 address";
    };
    anchorIPv4 = mkOption {
      type = types.str;
      description = "Anchor IPv4 address (required for some providers like DigitalOcean)";
    };
    publicIPv4 = mkOption {
      type = types.str;
      description = "Public IPv4 address to advertise";
    };
    monthlyLimitGB = mkOption {
      type = types.int;
      default = 750;
      description = "Monthly traffic limit in GBytes, will be split into 30 days";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.tor-relay-routing = {
      description = "Configure IP addresses and policy routing for Tor Relay";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "tor-routing-start" ''
          # Add IP addresses
          # Use nodad to make IPv6 available immediately (skip Duplicate Address Detection)
          # Use preferred_lft 0 to prevent these IPs from being used as default source addresses
          ${pkgs.iproute2}/bin/ip addr add ${cfg.anchorIPv4}/16 dev eth0 preferred_lft 0 || true
          ${pkgs.iproute2}/bin/ip -6 addr add ${cfg.ipv6}/128 dev eth0 nodad preferred_lft 0 || true

          # Configure routing
          ${pkgs.iproute2}/bin/ip route replace default via ${cfg.ipv4Gateway} dev eth0 onlink table 100
          ${pkgs.iproute2}/bin/ip rule del from ${cfg.anchorIPv4} table 100 priority 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip rule add from ${cfg.anchorIPv4} table 100 priority 100
        '';
        ExecStop = pkgs.writeShellScript "tor-routing-stop" ''
          # Remove routing
          ${pkgs.iproute2}/bin/ip rule del from ${cfg.anchorIPv4} table 100 priority 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip route del default table 100 2>/dev/null || true

          # Remove IP addresses
          ${pkgs.iproute2}/bin/ip addr del ${cfg.anchorIPv4}/16 dev eth0 || true
          ${pkgs.iproute2}/bin/ip -6 addr del ${cfg.ipv6}/128 dev eth0 || true
        '';
      };
    };

    systemd.services.tor.requires = [ "tor-relay-routing.service" ];
    systemd.services.tor.after = [ "tor-relay-routing.service" ];

    services.tor = {
      enable = true;
      relay = {
        enable = true;
        role = "relay";
      };
      settings = {
        ORPort = [
          { addr = cfg.anchorIPv4; port = 443; }
          { addr = "[${cfg.ipv6}]"; port = 443; }
        ];
        Address = cfg.publicIPv4;
        OutboundBindAddress = [ cfg.anchorIPv4 cfg.ipv6 ];
        
        AccountingMax = "${toString (cfg.monthlyLimitGB * 1024 / 30)} MBytes";
        AccountingStart = "day 00:00";
        
        Nickname = cfg.nickname;
        ContactInfo = cfg.contactInfo;
        
        ExitRelay = false;
      };
    };
  };
}
