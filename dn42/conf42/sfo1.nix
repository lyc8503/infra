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

  # TG @moohric
  networking.dn42.peers."2279" = {
    asn = 4242422279;
    listenPort = 22279;
    privateKey = secrets.key_do_sfo1;
    publicKey = "WCVsWHNq+VeafZ7agkfkafZIoC/8oHF46D07PkOVljA=";
    endpoint = "us-sjc1.bb.mhr.hk:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::2279";
    };
  };

  # https://dn42.routedbits.io/peering
  networking.dn42.peers."0207" = {
    asn = 4242420207;
    listenPort = 20207;
    privateKey = secrets.key_do_sfo1;
    publicKey = "s4uGYMeLV30vO/Z3+c1qrg/YA1eIMRVFYUsZEGD1hH8=";
    endpoint = "router.lax1.routedbits.com:50167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::207";
    };
  };

  # https://blog.moe233.net/dn42/
  networking.dn42.peers."0253" = {
    asn = 4242420253;
    listenPort = 20253;
    privateKey = secrets.key_do_sfo1;
    publicKey = "C3SneO68SmagisYQ3wi5tYI2R9g5xedKkB56Y7rtPUo=";
    endpoint = "lv.dn42.moe233.net:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::253";
    };
  };

  # TG @Potat0_DN42_Bot
  networking.dn42.peers."1816" = {
    asn = 4242421816;
    listenPort = 21816;
    privateKey = secrets.key_do_sfo1;
    publicKey = "LUwqKS6QrCPv510Pwt1eAIiHACYDsbMjrkrbGTJfviU=";
    endpoint = "las.node.potat0.cc:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1816";
    };
  };

  # TG @baka_lg_bot
  networking.dn42.peers."3374" = {
    asn = 4242423374;
    listenPort = 23374;
    privateKey = secrets.key_do_sfo1;
    publicKey = "p8ADoxb0sVm1ZBp9Fkom6IaP04dm1DLrpHQLfI9HpGY=";
    endpoint = "us01.dn42.baka.pub:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::3374";
    };
  };
}
