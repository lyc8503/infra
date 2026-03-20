{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.my-xray-vmess;
  configFile = pkgs.writeText "xray-vmess.json" (builtins.toJSON {
    log.loglevel = "warning";
    inbounds = [
      {
        port = cfg.vmessPort;
        protocol = "vmess";
        settings = {
          clients = [
            {
              id = cfg.uuid;
              alterId = 0;
            }
          ];
        };
        streamSettings = {
          network = "tcp";
          security = "none";
        };
      }
    ];
    outbounds = [
      {
        protocol = "freedom";
        settings = {};
      }
    ];
  });
in
{
  options.services.my-xray-vmess = {
    enable = mkEnableOption "My Xray VMess Service";

    uuid = mkOption {
      type = types.str;
      description = "UUID for VMess";
    };

    vmessPort = mkOption {
      type = types.port;
      default = 23390;
    };

    registration = {
      enable = mkEnableOption "Registration Service";
      subServer = mkOption { type = types.str; };
      regPassword = mkOption { type = types.str; };
      subId = mkOption { type = types.str; };
      traffic = mkOption { type = types.int; default = 100; };
      ipv4 = mkOption { type = types.bool; default = true; };
      ipv6 = mkOption { type = types.bool; default = false; };
      srcIpv4 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Source IPv4 to bind curl to when detecting public IP (e.g. anchor private IP so the sub server sees the Reserved/Floating IP).";
      };
      srcIpv6 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Source IPv6 to bind curl to when detecting public IPv6 (e.g. anchor extra IPv6 so the sub server sees the correct address).";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.xray-vmess = {
      description = "Xray VMess Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.xray}/bin/xray -config ${configFile}";
        Restart = "on-failure";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.vmessPort ];
    networking.firewall.allowedUDPPorts = [ cfg.vmessPort ];

    systemd.services.xray-vmess-register = mkIf cfg.registration.enable {
      description = "Xray VMess Registration Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "xray-vmess-register" ''
          export PATH=${lib.makeBinPath [ pkgs.curl pkgs.gnugrep pkgs.coreutils ]}:$PATH

          ${optionalString cfg.registration.ipv4 ''
          SELF_PUBLIC_IP=$(curl -4 -s ${optionalString (cfg.registration.srcIpv4 != null) "--interface ${cfg.registration.srcIpv4} "} https://ifconfig.me/ip)

          if [ -n "$SELF_PUBLIC_IP" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_vmess&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_vmess,type: vmess,server: $SELF_PUBLIC_IP,port: ${toString cfg.vmessPort},uuid: ${cfg.uuid},alterId: 0,cipher: auto,network: tcp,udp: true}"
          fi
          ''}

          ${optionalString cfg.registration.ipv6 ''
          SELF_PUBLIC_IPV6=$(curl -6 -s ${optionalString (cfg.registration.srcIpv6 != null) "--interface ${cfg.registration.srcIpv6} "} https://ifconfig.me/ip)

          if [ -n "$SELF_PUBLIC_IPV6" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_v6_vmess&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_v6_vmess,type: vmess,server: $SELF_PUBLIC_IPV6,port: ${toString cfg.vmessPort},uuid: ${cfg.uuid},alterId: 0,cipher: auto,network: tcp,udp: true}"
          fi
          ''}
        '';
      };
    };

    systemd.timers.xray-vmess-register = mkIf cfg.registration.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
