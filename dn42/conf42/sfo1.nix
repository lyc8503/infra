{ config, pkgs, lib, ... }:

let
  secrets = import ../secrets.nix;
in
{
  services.dn42-looking-glass = {
    enable = true;
    servers = [ "ams1" "sfo1" "sgp1" "syd1" "tor1" "blr1" ];
    domain = "dn42.42420167.xyz";
  };

  services.xjbcast = {
    enable = true;
    nodeName = "sfo1";
    ipv4Address = "172.23.41.81";
    ipv6Address = "fd32:3940:2738::1";
  };

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.addresses = [ "172.20.42.241" "172.23.41.81" ];
    ipv4.dnetAddress = "172.20.42.225";
    ipv4.networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
    ipv6.addresses = [ "fd00:1100:8503::2" "fd32:3940:2738::1" ];
    ipv6.networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
  };


  # TG @LeZi9916
  networking.dn42.peers."3377" = {
    asn = 4242423377;
    listenPort = 23377;
    privateKey = secrets.key_do_sfo1;
    publicKey = "Xzt9UrH2moj84QSH0jsw8Zj+jwXwdBLpApe4hHyfnAw=";
    endpoint = "v4.los1-us.peer.dn42.leziblog.com:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::3377";
    };
  };

  # TG @beacon_owo
  networking.dn42.peers."1117" = {
    asn = 4242421117;
    listenPort = 21117;
    privateKey = secrets.key_do_sfo1;
    publicKey = "PW/+rv0B8e4tUJ9j1TWscx1sl36WwhPh9adEqoM7Jic=";
    endpoint = "us01.dn42.yuyuko.com:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1117";
    };
  };

  # TG @iYoRoy
  networking.dn42.peers."2024" = {
    asn = 4242422024;
    listenPort = 22024;
    privateKey = secrets.key_do_sfo1;
    publicKey = "As0rZo5b9Bwt4loPGl6iSdtOqkd2p6ExK/Xyoy9OmTU=";
    endpoint = "ipv4.lax-us.ecs.iyoroy-infra.top:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::2024";
    };
  };

  # TG @charliemoomoo
  networking.dn42.peers."3999" = {
    asn = 4242423999;
    listenPort = 23999;
    privateKey = secrets.key_do_sfo1;
    publicKey = "jhOukGNAKHI8Ivn8uI1TS25n5ho/rVlKFfenGmwCVlg=";
    endpoint = "lax.node.cowgl.xyz:30167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::2:3999";
    };
  };
}
