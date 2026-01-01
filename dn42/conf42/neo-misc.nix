{ config, pkgs, lib, ... }:

let
  secrets = import ../secrets.nix;
in
{
  networking.dn42 = {
    useDnet = true;
    asn = 4242420167;
    ipv4.addresses = [ "172.20.42.246" ];
    ipv4.dnetAddress = "172.20.42.230";
    ipv4.networks = [ "172.20.42.224/27" ];
    ipv6.addresses = [ "fd00:1100:8503::7" ];
    ipv6.networks = [ "fd00:1100:8503::/48" ];
  };
}
