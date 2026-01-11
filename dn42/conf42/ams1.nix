{ config, pkgs, lib, ... }:

let
  secrets = import ../secrets.nix;
in
{
  services.dn42-looking-glass = {
    enable = true;
    servers = [ "ams1" "sfo1" "sgp1" ];
    domain = "dn42.42420167.xyz";
  };

  services.xjbcast = {
    enable = true;
    nodeName = "ams1";
    ipv4Address = "172.23.41.81";
    ipv6Address = "fd32:3940:2738::1";
  };

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.addresses = [ "172.20.42.242" "172.23.41.81" ];
    ipv4.dnetAddress = "172.20.42.226";
    ipv4.networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
    ipv6.addresses = [ "fd00:1100:8503::3" "fd32:3940:2738::1" ];
    ipv6.networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
  };


  # TG @imlonghao
  networking.dn42.peers."1888" = {
    asn = 4242421888;
    listenPort = 21888;
    privateKey = secrets.key_do_ams1;
    publicKey = "k9F2akSTkbA/GiO59PNW/v0D65ioMYD4P1DqeKSL3FM=";
    endpoint = "de1.dn42.ni.sb:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1888";
    };
  };

  # TG @baka_lg_bot
  networking.dn42.peers."3374" = {
    asn = 4242423374;
    listenPort = 23374;
    privateKey = secrets.key_do_ams1;
    publicKey = "xFZ0S57R5ykjq5lThYEvLLWHhv2+De5D26p4bX5wdSo=";
    endpoint = "de01.dn42.baka.pub:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::2999:232";
    };
  };

  # TG @HExpNetworkBot
  networking.dn42.peers."0298" = {
    asn = 4242420298;
    listenPort = 20298;
    privateKey = secrets.key_do_ams1;
    publicKey = "VMOGexXB0v+zWhxAjYk8r2tI/WQmfxCmd4nXb0GULBg=";
    endpoint = "node4.ox5.cc:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::298";
    };
  };
 
  # TG @charliemoomoo
  networking.dn42.peers."3999" = {
    asn = 4242423999;
    listenPort = 23999;
    privateKey = secrets.key_do_ams1;
    publicKey = "sHPUV74X+hqUK5wFj3m5kCga0rlPCxImUBwZ/oLiEn4=";
    endpoint = "brn.node.cowgl.xyz:30167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::3:3999";
    };
  };

  # https://blog.yuyuko.com/post/7
  networking.dn42.peers."1117" = {
    asn = 4242421117;
    listenPort = 21117;
    privateKey = secrets.key_do_ams1;
    publicKey = "9oVGKPUnxykn9y/CeNmHbImnX2WRsHk6VzSIAQfy0hc=";
    endpoint = "nl01.dn42.yuyuko.com:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1117";
    };
  };

  # TG @moohric
  networking.dn42.peers."2279" = {
    asn = 4242422279;
    listenPort = 22279;
    privateKey = secrets.key_do_ams1;
    publicKey = "cXdcdBVi0Yt78jmwGhnv+ju6dxSQ9YKX6xL7O91tmVw=";
    endpoint = "6.nl-ams1.bb.mhr.hk:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::2279";
    };
  };

  # TG @LeZi9916
  networking.dn42.peers."3377" = {
    asn = 4242423377;
    listenPort = 23377;
    privateKey = secrets.key_do_ams1;
    publicKey = "Kd5+CvZW3NRvUXpbdqGFt85VzMyReBtnVeDVXae06Qg=";
    endpoint = "v4.de1.peer.dn42.leziblog.com:20167";
    mtu = 1370;
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::3377";
    };
  };

  # https://dn42.routedbits.io/peering
  networking.dn42.peers."0207" = {
    asn = 4242420207;
    listenPort = 20207;
    privateKey = secrets.key_do_ams1;
    publicKey = "JjAHDWR1CgQd1HJNvURrqUECkN++0bzYxlm57VXjlyc=";
    endpoint = "router.ams1.routedbits.com:50167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::207";
    };
  };
}
