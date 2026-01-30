{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.traffic-limit;
in
{
  options.services.traffic-limit = {
    enable = mkEnableOption "monthly outbound traffic limit with automatic shutdown";

    limitGB = mkOption {
      type = types.int;
      description = "Monthly outbound traffic limit in GiB";
    };

    checkInterval = mkOption {
      type = types.str;
      default = "1min";
      description = "How often to check traffic usage";
    };

    dryRun = mkOption {
      type = types.bool;
      default = false;
      description = "If true, only log what would happen without actually shutting down";
    };
  };

  config = mkIf cfg.enable {
    services.vnstat.enable = true;

    systemd.services.monthly-outbound-shutdown = {
      description = "Shutdown when monthly outbound exceeds ${toString cfg.limitGB}GiB";
      serviceConfig = {
        Type = "oneshot";
      };
      path = [ pkgs.vnstat pkgs.jq pkgs.iproute2 pkgs.coreutils pkgs.gawk ];
      script = ''
        set -euo pipefail

        limit_bytes=$((${toString cfg.limitGB} * 1024 * 1024 * 1024))

        iface=$(${pkgs.iproute2}/bin/ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
        if [ -z "$iface" ]; then
          echo "No default route found, exiting"
          exit 0
        fi

        json=$(${pkgs.vnstat}/bin/vnstat --json -i "$iface" 2>/dev/null || true)
        if [ -z "$json" ]; then
          echo "No vnstat data available for $iface, exiting"
          exit 0
        fi

        year=$(${pkgs.coreutils}/bin/date +%Y)
        month=$((10#$(${pkgs.coreutils}/bin/date +%m)))

        tx_bytes=$(
          printf '%s' "$json" | ${pkgs.jq}/bin/jq -r --argjson y "$year" --argjson m "$month" \
            '.interfaces[0].traffic.month[] | select(.date.year==$y and .date.month==$m) | if .tx | type == "object" then .tx.bytes else .tx end' \
            | ${pkgs.coreutils}/bin/head -n1
        )

        if [ -z "$tx_bytes" ] || [ "$tx_bytes" = "null" ]; then
          echo "No traffic data for current month, exiting"
          exit 0
        fi

        tx_gb=$((tx_bytes / 1024 / 1024 / 1024))
        echo "Current monthly outbound: $tx_gb GiB / ${toString cfg.limitGB} GiB (interface: $iface)"

        if [ "$tx_bytes" -ge "$limit_bytes" ]; then
          ${if cfg.dryRun then ''
            echo "DRY RUN: Would shutdown now (limit exceeded: $tx_gb GiB >= ${toString cfg.limitGB} GiB)"
          '' else ''
            echo "Limit exceeded! Shutting down now..."
            ${pkgs.systemd}/bin/shutdown -h now "Monthly outbound >= ${toString cfg.limitGB}GiB"
          ''}
        fi
      '';
    };

    systemd.timers.monthly-outbound-shutdown = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.checkInterval;
        OnUnitActiveSec = cfg.checkInterval;
      };
    };
  };
}
