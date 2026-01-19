{ config, pkgs, lib, ... }:


let
  secrets = import ../../secrets.nix;
in
{
  imports = [
    ./hardware.nix
    ../../conf42/sgp1.nix
    ../../modules/dn42.nix
    ../../modules/ibgp-full-mesh.nix

    ../../modules/common.nix
    ../../modules/metrics.nix
    ../../modules/tcpdump.nix
    ../../modules/looking-glass.nix
  ];

  deployment = {
    targetHost = "hwsg";
    targetUser = "root";
  };

  system.stateVersion = "25.11";

  networking.hostName = "neo-misc";

  # HE IPv6 Tunnel
  systemd.services.he-ipv6 = {
    description = "HE IPv6 tunnel";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.kmod}/bin/modprobe ipv6
      ${pkgs.iproute2}/bin/ip tunnel add he-ipv6 mode sit remote 216.218.221.42 local 192.168.15.189 ttl 255 || true
      ${pkgs.iproute2}/bin/ip link set he-ipv6 up
      ${pkgs.iproute2}/bin/ip addr add 2001:470:35:50a::2/64 dev he-ipv6 || true
      ${pkgs.iproute2}/bin/ip addr add 2001:470:ecb0::1/48 dev he-ipv6 || true
      ${pkgs.iproute2}/bin/ip route add ::/0 dev he-ipv6 || true
    '';
    postStop = ''
      ${pkgs.iproute2}/bin/ip link set he-ipv6 down || true
      ${pkgs.iproute2}/bin/ip tunnel del he-ipv6 || true
    '';
  };

  services.dnet-core.externalInterface = "ens3";

  # Alloy Metrics
  services.metrics = {
    enable = true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  # Caddy
  services.caddy = {
    enable = true;
    virtualHosts."http://sub.${secrets.misc_domain}".extraConfig = "reverse_proxy 127.0.0.1:8002";
    virtualHosts."http://bot.${secrets.misc_domain}".extraConfig = "reverse_proxy 127.0.0.1:8001";
    virtualHosts."http://da.lyc8503.net".extraConfig = "reverse_proxy 127.0.0.1:3000";
  };

  # Docker Compose Service
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [ docker-compose ];
  systemd.services.misc-docker = {
    description = "Misc Docker Compose Project";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "network.target" ];
    restartTriggers = [ "${./docker}" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/opt/misc-docker";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d --remove-orphans --build";
    };
  };

  system.activationScripts.misc-docker = ''
    rm -rf /opt/misc-docker
    mkdir -p /opt/misc-docker
    for f in ${./docker}/*; do
      ln -sf $f /opt/misc-docker/$(basename $f)
    done
    cat > /opt/misc-docker/.env <<EOF
    ADMIN_PASSWORD=${secrets.sub_admin_password}
    REG_PASSWORD=${secrets.sub_reg_password}
    BOT_TOKEN=${secrets.tgbot_token}
    CHAT_ID=${secrets.tgbot_chat_id}
    PUSH_KEY=${secrets.tgbot_push_key}
    SELF_URL=${secrets.tgbot_self_url}
    SECRET_TOKEN=${secrets.tgbot_secret_token}
    TOKEN=${secrets.tgrss_token}
    MANAGER=${secrets.tgrss_manager}
    LOKI_TOKEN=${secrets.log_forward_loki_token}
    APP_SECRET=${secrets.umami_app_secret}
    EOF
  '';
}
