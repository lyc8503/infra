{ config, pkgs, lib, ... }:

let
  secrets = import ../secrets.nix;
in
{
  services.dn42-looking-glass = {
    enable = true;
    servers = [ "ams1" "sfo1" "sgp1" "sgp2" "hkg1" "chs1" ];
    domain = "dn42.42420167.xyz";
  };

  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.addresses = [ "172.20.42.229" ];
    ipv4.dnetAddress = "172.20.42.245";
    ipv4.networks = [ "172.20.42.224/27" ];
    ipv6.addresses = [ "fd00:1100:8503::6" ];
    ipv6.networks = [ "fd00:1100:8503::/48" ];
  };
}
