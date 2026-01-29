{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.my-xray;
in
{
  options.services.my-xray = {
    enable = mkEnableOption "My Xray Service";
    
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
      ipv6 = mkOption { type = types.bool; default = false; };
      realityPublicKey = mkOption { type = types.str; };
    };
  };

  config = mkIf cfg.enable {
    services.xray = {
      enable = true;
      settings = {
        log = {
          loglevel = "warning";
        };
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
      };
    };
    
    networking.firewall.allowedTCPPorts = [ cfg.visionPort ];
    networking.firewall.allowedUDPPorts = [ cfg.visionPort ];

    systemd.services.xray.serviceConfig = {
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
    };

    systemd.services.xray-register = mkIf cfg.registration.enable {
      description = "Xray Registration Service";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "xray-register" ''
          export PATH=${lib.makeBinPath [ pkgs.curl pkgs.gnugrep pkgs.coreutils ]}:$PATH
          
          dest_host=$(echo "${cfg.realityDest}" | cut -d: -f1)
          
          SELF_PUBLIC_IP=$(curl -4 -s https://1.1.1.1/cdn-cgi/trace | grep 'ip=' | cut -c4-)

          if [ -n "$SELF_PUBLIC_IP" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_vision&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_vision_reality,type: vless,server: $SELF_PUBLIC_IP,port: ${toString cfg.visionPort},uuid: ${cfg.uuid},network: tcp,tls: true,udp: true,flow: xtls-rprx-vision,servername: $dest_host,reality-opts: {public-key: ${cfg.registration.realityPublicKey},short-id: ae},client-fingerprint: chrome}"
          fi

          ${optionalString cfg.registration.ipv6 ''
          SELF_PUBLIC_IPV6=$(curl -6 -s https://[2606:4700:4700::1111]/cdn-cgi/trace | grep 'ip=' | cut -c4-)
          
          if [ -n "$SELF_PUBLIC_IPV6" ]; then
              curl -G '${cfg.registration.subServer}?token=${cfg.registration.regPassword}&id=${cfg.registration.subId}_v6_vision&traffic=${toString cfg.registration.traffic}' --data-urlencode "subscription={name: ${cfg.registration.subId}_v6_vision_reality,type: vless,server: $SELF_PUBLIC_IPV6,port: ${toString cfg.visionPort},uuid: ${cfg.uuid},network: tcp,tls: true,udp: true,flow: xtls-rprx-vision,servername: $dest_host,reality-opts: {public-key: ${cfg.registration.realityPublicKey},short-id: ae},client-fingerprint: chrome}"
          fi
          ''}
        '';
      };
    };

    systemd.timers.xray-register = mkIf cfg.registration.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
