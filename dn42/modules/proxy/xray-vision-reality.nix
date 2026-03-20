{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.my-xray-vision-reality;
  configFile = pkgs.writeText "xray-vision-reality.json" (builtins.toJSON {
    log.loglevel = "warning";
    inbounds = [
      {
        port = cfg.visionPort;
        protocol = "vless";
        settings = {
          clients = [
            {
              id = cfg.uuid;
              flow = "xtls-rprx-vision";
            }
          ];
          decryption = "none";
        };
        streamSettings = {
          network = "tcp";
          security = "reality";
          realitySettings = {
            dest = cfg.realityDest;
            serverNames = [ (head (splitString ":" cfg.realityDest)) ];
            privateKey = cfg.realityPrivateKey;
            shortIds = cfg.realityShortIds;
          };
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
  options.services.my-xray-vision-reality = {
    enable = mkEnableOption "My Xray Vision+Reality Service";

    uuid = mkOption {
      type = types.str;
      description = "UUID for VLESS";
    };

    visionPort = mkOption {
      type = types.port;
      default = 443;
    };

    realityDest = mkOption {
      type = types.str;
      default = "www.example.com:443";
    };

    realityPrivateKey = mkOption {
      type = types.str;
    };

    realityShortIds = mkOption {
      type = types.listOf types.str;
      default = [ "" "ae" ];
    };

    registration = {
      enable = mkEnableOption "Registration Service";
      subServer = mkOption { type = types.str; };
      regPassword = mkOption { type = types.str; };
      subId = mkOption { type = types.str; };
      traffic = mkOption { type = types.int; default = 100; };
      ipv4 = mkOption { type = types.bool; default = true; };
      ipv6 = mkOption { type = types.bool; default = false; };
      realityPublicKey = mkOption { type = types.str; };
      shortId = mkOption { type = types.str; default = "ae"; };
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
    systemd.services.xray-vision-reality = {
      description = "Xray Vision+Reality Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.xray}/bin/xray -config ${configFile}";
        Restart = "on-failure";
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.visionPort ];
    networking.firewall.allowedUDPPorts = [ cfg.visionPort ];

    systemd.services.xray-vision-reality-register = mkIf cfg.registration.enable {
      description = "Xray Vision+Reality Registration Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "xray-vision-reality-register" ''
          export PATH=${lib.makeBinPath [ pkgs.curl pkgs.gnugrep pkgs.coreutils ]}:$PATH

          dest_host=$(echo "${cfg.realityDest}" | cut -d: -f1)

          ${optionalString cfg.registration.ipv4 ''
          SELF_PUBLIC_IP=$(curl -4 -s ${optionalString (cfg.registration.srcIpv4 != null) "--interface ${cfg.registration.srcIpv4} "} https://ifconfig.me/ip)

          if [ -n "$SELF_PUBLIC_IP" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_vision&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_vision_reality,type: vless,server: $SELF_PUBLIC_IP,port: ${toString cfg.visionPort},uuid: ${cfg.uuid},network: tcp,tls: true,udp: true,flow: xtls-rprx-vision,servername: $dest_host,reality-opts: {public-key: ${cfg.registration.realityPublicKey},short-id: ${cfg.registration.shortId}},client-fingerprint: chrome}"
          fi
          ''}

          ${optionalString cfg.registration.ipv6 ''
          SELF_PUBLIC_IPV6=$(curl -6 -s ${optionalString (cfg.registration.srcIpv6 != null) "--interface ${cfg.registration.srcIpv6} "} https://ifconfig.me/ip)

          if [ -n "$SELF_PUBLIC_IPV6" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_v6_vision&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_v6_vision_reality,type: vless,server: $SELF_PUBLIC_IPV6,port: ${toString cfg.visionPort},uuid: ${cfg.uuid},network: tcp,tls: true,udp: true,flow: xtls-rprx-vision,servername: $dest_host,reality-opts: {public-key: ${cfg.registration.realityPublicKey},short-id: ${cfg.registration.shortId}},client-fingerprint: chrome}"
          fi
          ''}
        '';
      };
    };

    systemd.timers.xray-vision-reality-register = mkIf cfg.registration.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
