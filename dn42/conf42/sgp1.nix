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

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.addresses = [ "172.20.42.240" "172.23.41.81" ];
    ipv4.dnetAddress = "172.20.42.224";
    ipv4.networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
    ipv6.addresses = [ "fd00:1100:8503::1" "fd32:3940:2738::1" ];
    ipv6.networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
  };

  networking.dn42.peers.ams1 = {
    asn = 4242420167;
    listenPort = 10001;
    privateKey = secrets.key_do_sgp1;
    publicKey = secrets.key_do_ams1_pub;
    endpoint = "ams1.dn42.42420167.xyz:10003";
    ipv6 = {
      local = "fe80::3";
      remote = "fe80::1";
    };
  };

  networking.dn42.peers.sfo1 = {
    asn = 4242420167;
    listenPort = 10002;
    privateKey = secrets.key_do_sgp1;
    publicKey = secrets.key_do_sfo1_pub;
    endpoint = "sfo1.dn42.42420167.xyz:10003";
    ipv6 = {
      local = "fe80::3";
      remote = "fe80::2";
    };
  };
  
  # https://dn42.g-load.eu/
  networking.dn42.peers."3914" = {
    asn = 4242423914;
    listenPort = 23914;
    privateKey = secrets.key_do_sgp1;
    publicKey = "sLbzTRr2gfLFb24NPzDOpy8j09Y6zI+a7NkeVMdVSR8=";
    endpoint = "hk1.g-load.eu:20167";
    
    ipv6 = {
      local = "fe80::ade1";
      remote = "fe80::ade0";
    };
    
    # ipv4 = {
    #   local = "172.20.42.224";
    #   remote = "172.20.53.105";
    # };
  };

  # Email wyf@932686.xyz
  networking.dn42.peers."2034" = {
    asn = 4242422034;
    listenPort = 22034;
    privateKey = secrets.key_do_sgp1;
    publicKey = "Zl72hWVO9Ib3ylYqKpDCEq8VyiJjY0WDhXP+vX+CzFs=";
    endpoint = "v1.932.moe:20167";
    ipv6 = {
      local = "fe80::1067";
      remote = "fe80::2034";
    };

    # ipv4 = {
    #   local = "172.20.42.224";
    #   remote = "172.21.104.33";
    # };
  };

  # TG @moohric
  networking.dn42.peers."2279" = {
    asn = 4242422279;
    listenPort = 22279;
    privateKey = secrets.key_do_sgp1;
    publicKey = "Yu5PP+dKWqFCWSOqzEd2d3YGPZDOs7bgxQfZiNJjJH4=";
    endpoint = "sg-sin1.bb.mhr.hk:20167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::2279";
    };
  };

  # QQ
  networking.dn42.peers."1313" = {
    asn = 4242421313;
    listenPort = 21313;
    privateKey = secrets.key_do_sgp1;
    publicKey = "nDppZOorVG2qZgS7++ZIDeQWLFDCGYIZBZepdiDCJXU=";
    endpoint = "140.245.41.240:48372";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::1313";
    };
  };

  # TG @charliemoomoo
  networking.dn42.peers."3999" = {
    asn = 4242423999;
    listenPort = 23999;
    privateKey = secrets.key_do_sgp1;
    publicKey = "mGGBczSVKW+7UKRquI2GkbKrfxiATv9r4uF5WTP+vWI=";
    endpoint = "hkg.node.cowgl.xyz:30167";
    ipv6 = {
      local = "fe80::167";
      remote = "fe80::3999";
    };
  };
}
