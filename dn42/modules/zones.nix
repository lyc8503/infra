{ config, pkgs, lib, ... }:

let
  domain = "42420167.xyz";
  
  hosts = {
    sfo1 = {
      ipv4 = "64.227.99.106";
      ipv6 = "2604:a880:4:1d0:0:1:4500:1000";
    };
    ams1 = {
      ipv4 = "165.22.195.57";
      ipv6 = "2a03:b0c0:2:f0:0:1:1760:e001";
    };
    sgp1 = {
      ipv4 = "167.99.65.156";
      ipv6 = "2400:6180:0:d2:0:2:7490:d000";
    };
  };

  zoneFile = pkgs.writeText "dn42.zone" ''
    @ 3600 IN SOA ns1.${domain}. admin.${domain}. (
      2025121201 ; serial
      7200       ; refresh
      3600       ; retry
      86400      ; expire
      3600       ; minimum
    )

    @ 3600 IN NS ns1.${domain}.
    @ 3600 IN NS ns2.${domain}.
    @ 3600 IN NS ns3.${domain}.

    ns1 3600 IN A ${hosts.sfo1.ipv4}
    ns2 3600 IN A ${hosts.ams1.ipv4}
    ns3 3600 IN A ${hosts.sgp1.ipv4}

    sfo1.dn42 3600 IN A ${hosts.sfo1.ipv4}
    v6.sfo1.dn42 3600 IN AAAA ${hosts.sfo1.ipv6}

    ams1.dn42 3600 IN A ${hosts.ams1.ipv4}
    v6.ams1.dn42 3600 IN AAAA ${hosts.ams1.ipv6}

    sgp1.dn42 3600 IN A ${hosts.sgp1.ipv4}
    v6.sgp1.dn42 3600 IN AAAA ${hosts.sgp1.ipv6}
  '';

in
{
  services.dn42-dns = {
    enable = true;
    domain = domain;
    zoneFile = zoneFile;
  };
}
