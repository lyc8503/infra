{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.metrics;
in
{
  options.services.metrics = {
    enable = mkEnableOption "metrics collection using Grafana Alloy";

    push_endpoint = mkOption {
      type = types.str;
      description = "Prometheus remote write endpoint";
    };

    loki_endpoint = mkOption {
      type = types.str;
      description = "Loki remote write endpoint";
    };
  };

  config = mkIf cfg.enable {
    services.alloy.enable = true;
    environment.etc."alloy/config.alloy".text = ''
        prometheus.exporter.unix "local_system" {
          disable_collectors = ["systemd"]
          netclass {
            ignored_devices = "^(br|veth|fw).*"
          }
        }

        prometheus.scrape "scrape_metrics" {
          targets = prometheus.exporter.unix.local_system.targets
          forward_to = [prometheus.relabel.filter_metrics.receiver]
        }

        prometheus.relabel "filter_metrics" {
          forward_to = [prometheus.remote_write.prom.receiver]
        }

        prometheus.remote_write "prom" {
          endpoint {
            url = "${cfg.push_endpoint}"
          }
        }

        loki.source.journal "read"  {
          forward_to    = [loki.write.endpoint.receiver]
          labels        = {component = "${config.networking.hostName}"}
        }

        loki.write "endpoint" {
          endpoint {
            url = "${cfg.loki_endpoint}"
          }
        }
      '';
  };
}
