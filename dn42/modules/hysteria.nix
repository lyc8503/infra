{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.my-hysteria;
in
{
  options.services.my-hysteria = {
    enable = mkEnableOption "My Hysteria Service";

    package = mkOption {
      type = types.package;
      default = pkgs.hysteria;
      description = "The hysteria package to use";
    };

    port = mkOption {
      type = types.port;
      default = 8443;
    };

    password = mkOption {
      type = types.str;
    };

    registration = {
      enable = mkEnableOption "Registration Service";
      subServer = mkOption { type = types.str; };
      regPassword = mkOption { type = types.str; };
      subId = mkOption { type = types.str; };
      traffic = mkOption { type = types.int; default = 100; };
      ipv6 = mkOption { type = types.bool; default = false; };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.hysteria = {
      description = "Hysteria 2 Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/hysteria server -c /etc/hysteria/config.yaml";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "hysteria";
        ConfigurationDirectory = "hysteria";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW";
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW";
        NoNewPrivileges = true;
      };

      preStart = ''
        if [ ! -f /var/lib/hysteria/server.key ]; then
          ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:3072 -keyout /var/lib/hysteria/server.key -out /var/lib/hysteria/server.crt -sha256 -days 3650 -nodes -subj "/CN=server"
          chmod 644 /var/lib/hysteria/server.key
        fi
      '';
    };

    environment.etc."hysteria/config.yaml".text = ''
      listen: :${toString cfg.port}

      tls:
        cert: /var/lib/hysteria/server.crt
        key: /var/lib/hysteria/server.key

      auth:
        type: password
        password: ${cfg.password}
    '';

    networking.firewall.allowedTCPPorts = [ cfg.port ];
    networking.firewall.allowedUDPPorts = [ cfg.port ];

    systemd.services.hysteria-register = mkIf cfg.registration.enable {
      description = "Hysteria Registration Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "hysteria-register" ''
          export PATH=${lib.makeBinPath [ pkgs.curl pkgs.gnugrep pkgs.coreutils ]}:$PATH
          
          SELF_PUBLIC_IP=$(curl -4 -s https://1.1.1.1/cdn-cgi/trace | grep 'ip=' | cut -c4-)

          if [ -n "$SELF_PUBLIC_IP" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_hy2&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_hy2,type: hysteria2,server: $SELF_PUBLIC_IP,port: ${toString cfg.port},password: ${cfg.password},skip-cert-verify: true,client-fingerprint: chrome}"
          fi

          ${optionalString cfg.registration.ipv6 ''
          SELF_PUBLIC_IPV6=$(curl -6 -s https://[2606:4700:4700::1111]/cdn-cgi/trace | grep 'ip=' | cut -c4-)
          
          if [ -n "$SELF_PUBLIC_IPV6" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_v6_hy2&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_v6_hy2,type: hysteria2,server: $SELF_PUBLIC_IPV6,port: ${toString cfg.port},password: ${cfg.password},skip-cert-verify: true,client-fingerprint: chrome}"
          fi
          ''}
        '';
      };
    };

    systemd.timers.hysteria-register = mkIf cfg.registration.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
