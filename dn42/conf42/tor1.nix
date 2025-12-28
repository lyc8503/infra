{ config, pkgs, lib, ... }:

let
  secrets = import ../secrets.nix;
in
{
  services.dn42-looking-glass = {
    enable = true;
    servers = [ "ams1" "sfo1" "sgp1" "syd1" "tor1" "lon1" ];
    domain = "dn42.42420167.xyz";
  };

  services.xjbcast = {
    enable = true;
    nodeName = "tor1";
    ipv4Address = "172.23.41.81";
    ipv6Address = "fd32:3940:2738::1";
  };

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.addresses = [ "172.20.42.244" "172.23.41.81" ];
    ipv4.dnetAddress = "172.20.42.228";
    ipv4.networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
    ipv6.addresses = [ "fd00:1100:8503::5" "fd32:3940:2738::1" ];
    ipv6.networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
  };

  
  # https://dn42.routedbits.io/peering
  networking.dn42.peers."0207" = {
    asn = 4242420207;
    listenPort = 20207;
    privateKey = secrets.key_do_tor1;
    publicKey = "+5TlmsmGyXgIAv4Ej8yTum0sHQ+PWNkhcznnC+lv12M=";
    endpoint = "router.tor1.routedbits.com:50167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::207";
    };
  };

  # TG @charliemoomoo
  networking.dn42.peers."3999" = {
    asn = 4242423999;
    listenPort = 23999;
    privateKey = secrets.key_do_tor1;
    publicKey = "XGIBvqoUOgb8IiLIWtO9JVNZc4SEpEAM1eWh26MtoRE=";
    endpoint = "yyz.node.cowgl.xyz:30167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::5:3999";
    };
  };

  # TG @LeZi9916
  networking.dn42.peers."3377" = {
    asn = 4242423377;
    listenPort = 23377;
    privateKey = secrets.key_do_tor1;
    publicKey = "3g3PDuwQCak26e760RurWm684Ur7CG3k+dwRsQgzyxU=";
    endpoint = "v4.ca1-yyz.peer.dn42.leziblog.com:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::3377";
    };
  };
}
