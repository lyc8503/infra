{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.anchor-routing;
in
{
  options.services.anchor-routing = {
    enable = mkEnableOption "Anchor IP policy routing";

    anchorIPv4 = mkOption {
      type = types.str;
      description = "Private anchor IPv4 address (e.g. DO reserved IP anchor). Added to eth0 with preferred_lft 0 so it is not used as the default source address.";
    };

    ipv4Gateway = mkOption {
      type = types.str;
      description = "Gateway for the anchor subnet. Used to populate routing table 100 for policy routing.";
    };

    extraIPv6 = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional extra IPv6 /128 address to add to eth0 (nodad, preferred_lft 0). Used e.g. for Tor relay ORPort without letting Tor manage IP addresses itself.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.anchor-routing = {
      description = "Configure anchor IP and policy routing";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "anchor-routing-start" ''
          # Add anchor IPv4 with preferred_lft 0:
          # - the address is reachable (can bind to it with --interface)
          # - but it won't be picked as the default outbound source
          ${pkgs.iproute2}/bin/ip addr add ${cfg.anchorIPv4}/16 dev eth0 preferred_lft 0 || true

          ${optionalString (cfg.extraIPv6 != null) ''
          # Add extra IPv6 address (nodad + preferred_lft 0: immediate, not default source)
          ${pkgs.iproute2}/bin/ip -6 addr add ${cfg.extraIPv6}/128 dev eth0 nodad preferred_lft 0 || true
          ''}

          # Policy routing table 100: traffic *from* anchor IP goes via anchor gateway
          ${pkgs.iproute2}/bin/ip route replace default via ${cfg.ipv4Gateway} dev eth0 onlink table 100
          ${pkgs.iproute2}/bin/ip rule del from ${cfg.anchorIPv4} table 100 priority 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip rule add from ${cfg.anchorIPv4} table 100 priority 100
        '';
        ExecStop = pkgs.writeShellScript "anchor-routing-stop" ''
          ${pkgs.iproute2}/bin/ip rule del from ${cfg.anchorIPv4} table 100 priority 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip route del default table 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip addr del ${cfg.anchorIPv4}/16 dev eth0 || true
          ${optionalString (cfg.extraIPv6 != null) ''
          ${pkgs.iproute2}/bin/ip -6 addr del ${cfg.extraIPv6}/128 dev eth0 || true
          ''}
        '';
      };
    };
  };
}
