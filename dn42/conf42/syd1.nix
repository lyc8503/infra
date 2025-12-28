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
    nodeName = "syd1";
    ipv4Address = "172.23.41.81";
    ipv6Address = "fd32:3940:2738::1";
  };

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.addresses = [ "172.20.42.243" "172.23.41.81" ];
    ipv4.dnetAddress = "172.20.42.227";
    ipv4.networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
    ipv6.addresses = [ "fd00:1100:8503::4" "fd32:3940:2738::1" ];
    ipv6.networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
  };

  # https://dn42.routedbits.io/peering
  networking.dn42.peers."0207" = {
    asn = 4242420207;
    listenPort = 20207;
    privateKey = secrets.key_do_syd1;
    publicKey = "wgCrE2lSvrfctVSngdHo6iAT/RRK7gNldJcFIFKi/Go=";
    endpoint = "router.syd1.routedbits.com:50167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::207";
    };
  };

  # TG @Potat0_DN42_Bot
  networking.dn42.peers."1816" = {
    asn = 4242421816;
    listenPort = 21816;
    privateKey = secrets.key_do_syd1;
    publicKey = "BRBdho23apYZttFbSFvLLEhR59F0dBQgKB3YFychGHQ=";
    endpoint = "syd.node.potat0.cc:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1816";
    };
  };
}
