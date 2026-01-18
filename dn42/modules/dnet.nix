{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnet-core;
  secrets = import ../secrets.nix;
  
  dnsRecord = pkgs.writeText "DNSRecord.h" ''
    #ifndef DNET_DNS_RECORD_H
    #define DNET_DNS_RECORD_H

    #include "DNS.h"
    #include <cstring>

    void register_dns_records(std::unordered_multimap<record_key, record_value>& dns_records) {
        REGISTER_GENERIC_RECORD(TYPE_SOA, "42420167.xyz",
            34,
            "\x03\x6e\x73\x31\xc0\x0c\x05\x61\x64\x6d\x69\x6e\xc0\x0c\x78\xb4\xe5\xb1\x00\x00\x1c\x20\x00\x00\x0e\x10\x00\x01\x51\x80\x00\x00\x0e\x10"
        );
        REGISTER_GENERIC_RECORD(TYPE_NS, "42420167.xyz",
            6,
            "\x03ns1\xc0\x0c"
        );
        REGISTER_GENERIC_RECORD(TYPE_NS, "42420167.xyz",
            6,
            "\x03ns2\xc0\x0c"
        );
        REGISTER_A_RECORD("ns1.42420167.xyz", "188.239.22.57");
        REGISTER_A_RECORD("ns2.42420167.xyz", "64.227.99.106");

        // Physical Hostnames
        REGISTER_A_RECORD("do-sfo1.dn42.42420167.xyz", "64.227.99.106");
        REGISTER_GENERIC_RECORD(TYPE_AAAA, "do-sfo1.dn42.42420167.xyz", 16, "\x26\x04\xa8\x80\x00\x04\x01\xd0\x00\x00\x00\x01\x45\x00\x10\x00");
        REGISTER_GENERIC_RECORD(TYPE_AAAA, "scw-ams1.dn42.42420167.xyz", 16, "\x20\x01\x0d\xb8\x16\x40\x4f\x16\xf5\xbf\xe8\xbf\xfd\x1d\xe6\x5a");
        REGISTER_A_RECORD("neo-misc.dn42.42420167.xyz", "188.239.22.57");
        REGISTER_A_RECORD("az-sg-1-ats.dn42.42420167.xyz", "13.76.30.153");
        REGISTER_A_RECORD("az-hk-1-arm.dn42.42420167.xyz", "20.2.153.221");
        REGISTER_A_RECORD("gcp-chs1.dn42.42420167.xyz", "35.211.99.153");

        // Logical Node names (CNAME to Hostnames)
        REGISTER_CNAME_RECORD("ams1.dn42.42420167.xyz", "scw-ams1.dn42.42420167.xyz");
        REGISTER_CNAME_RECORD("sfo1.dn42.42420167.xyz", "do-sfo1.dn42.42420167.xyz");
        REGISTER_CNAME_RECORD("sgp1.dn42.42420167.xyz", "neo-misc.dn42.42420167.xyz");
        REGISTER_CNAME_RECORD("sgp2.dn42.42420167.xyz", "az-sg-1-ats.dn42.42420167.xyz");
        REGISTER_CNAME_RECORD("hkg1.dn42.42420167.xyz", "az-hk-1-arm.dn42.42420167.xyz");
        REGISTER_CNAME_RECORD("chs1.dn42.42420167.xyz", "gcp-chs1.dn42.42420167.xyz");

        auto register_txt = [&](const char* name, const char* text) {
            size_t len = strlen(text);
            char* rdata = new char[len + 1];
            rdata[0] = (char)len;
            memcpy(rdata + 1, text, len);
            REGISTER_GENERIC_RECORD(16, name, len + 1, rdata);
            delete[] rdata;
        };

        register_txt("ams1.dn42.42420167.xyz", "ASN: 4242420167");
        register_txt("ams1.dn42.42420167.xyz", "Endpoint: ams1.dn42.42420167.xyz:2xxxx (xxxx is the last 4 digits of your ASN)");
        register_txt("ams1.dn42.42420167.xyz", "IPv6 LLA: fe80::167");
        register_txt("ams1.dn42.42420167.xyz", "PubKey: ${secrets.key_ams1_pub}");
        register_txt("ams1.dn42.42420167.xyz", "MP-BGP: enabled");
        register_txt("ams1.dn42.42420167.xyz", "Extended Next Hop: enabled");
        register_txt("ams1.dn42.42420167.xyz", "Looking Glass: http://ams1.dn42.42420167.xyz:5000/");
        register_txt("ams1.dn42.42420167.xyz", "Please provide me with your endpoint/port/pubkey/link-local address so I can peer with you!");

        register_txt("sfo1.dn42.42420167.xyz", "ASN: 4242420167");
        register_txt("sfo1.dn42.42420167.xyz", "Endpoint: sfo1.dn42.42420167.xyz:2xxxx (xxxx is the last 4 digits of your ASN)");
        register_txt("sfo1.dn42.42420167.xyz", "IPv6 LLA: fe80::167");
        register_txt("sfo1.dn42.42420167.xyz", "PubKey: ${secrets.key_sfo1_pub}");
        register_txt("sfo1.dn42.42420167.xyz", "MP-BGP: enabled");
        register_txt("sfo1.dn42.42420167.xyz", "Extended Next Hop: enabled");
        register_txt("sfo1.dn42.42420167.xyz", "Looking Glass: http://sfo1.dn42.42420167.xyz:5000/");
        register_txt("sfo1.dn42.42420167.xyz", "Please provide me with your endpoint/port/pubkey/link-local address so I can peer with you!");

        register_txt("sgp1.dn42.42420167.xyz", "ASN: 4242420167");
        register_txt("sgp1.dn42.42420167.xyz", "Endpoint: sgp1.dn42.42420167.xyz:2xxxx (xxxx is the last 4 digits of your ASN)");
        register_txt("sgp1.dn42.42420167.xyz", "IPv6 LLA: fe80::167");
        register_txt("sgp1.dn42.42420167.xyz", "PubKey: ${secrets.key_sgp1_pub}");
        register_txt("sgp1.dn42.42420167.xyz", "MP-BGP: enabled");
        register_txt("sgp1.dn42.42420167.xyz", "Extended Next Hop: enabled");
        register_txt("sgp1.dn42.42420167.xyz", "Looking Glass: http://sgp1.dn42.42420167.xyz:5000/");
        register_txt("sgp1.dn42.42420167.xyz", "Please provide me with your endpoint/port/pubkey/link-local address so I can peer with you!");

        register_txt("chs1.dn42.42420167.xyz", "ASN: 4242420167");
        register_txt("chs1.dn42.42420167.xyz", "Endpoint: chs1.dn42.42420167.xyz:2xxxx (xxxx is the last 4 digits of your ASN)");
        register_txt("chs1.dn42.42420167.xyz", "IPv6 LLA: fe80::167");
        register_txt("chs1.dn42.42420167.xyz", "PubKey: ${secrets.key_chs1_pub}");
        register_txt("chs1.dn42.42420167.xyz", "MP-BGP: enabled");
        register_txt("chs1.dn42.42420167.xyz", "Extended Next Hop: enabled");
        register_txt("chs1.dn42.42420167.xyz", "Please provide me with your endpoint/port/pubkey/link-local address so I can peer with you!");

        register_txt("sgp2.dn42.42420167.xyz", "ASN: 4242420167");
        register_txt("sgp2.dn42.42420167.xyz", "Endpoint: sgp2.dn42.42420167.xyz:2xxxx (xxxx is the last 4 digits of your ASN)");
        register_txt("sgp2.dn42.42420167.xyz", "IPv6 LLA: fe80::167");
        register_txt("sgp2.dn42.42420167.xyz", "PubKey: ${secrets.key_sgp2_pub}");
        register_txt("sgp2.dn42.42420167.xyz", "MP-BGP: enabled");
        register_txt("sgp2.dn42.42420167.xyz", "Extended Next Hop: enabled");

        register_txt("hkg1.dn42.42420167.xyz", "ASN: 4242420167");
        register_txt("hkg1.dn42.42420167.xyz", "Endpoint: hkg1.dn42.42420167.xyz:2xxxx (xxxx is the last 4 digits of your ASN)");
        register_txt("hkg1.dn42.42420167.xyz", "IPv6 LLA: fe80::167");
        register_txt("hkg1.dn42.42420167.xyz", "PubKey: ${secrets.key_hkg1_pub}");
        register_txt("hkg1.dn42.42420167.xyz", "MP-BGP: enabled");
        register_txt("hkg1.dn42.42420167.xyz", "Extended Next Hop: enabled");
    }
    #endif // DNET_DNS_RECORD_H
  '';
  
  dnet-core = pkgs.stdenv.mkDerivation {
    pname = "dnet-core";
    version = "0.0.1-unstable-2025-12-21";

    src = pkgs.fetchFromGitHub {
      owner = "lyc8503";
      repo = "DNet-core";
      rev = "b6aa2c4ed4f25ca8762f0de1c14578df239629a0";
      sha256 = "sha256-lOJNXRKV89F6u0ek/JpLT8aIFj1edZHPfHI94FLwE4E=";
    };

    nativeBuildInputs = [ pkgs.cmake ];

    postPatch = ''
      cp ${dnsRecord} layers/L7/DNSRecord.h
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp DNet $out/bin/dnet-core
    '';
  };
in
{
  options.services.dnet-core = {
    enable = mkEnableOption "DNet-core service";
    ip = mkOption {
      type = types.str;
      description = "IP address/Network address for DNet-core";
    };
    netmask = mkOption {
      type = types.str;
      description = "Netmask for DNet-core";
    };
    cidr = mkOption {
      type = types.str;
      description = "CIDR for route (e.g. 172.20.42.224/27)";
    };
    externalInterface = mkOption {
      type = types.str;
      description = "External interface for NAT";
      default = "eth0";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.dnet-nat = {
      description = "DNet NAT rules";
      after = [ "network.target" "firewall.service" ];
      wants = [ "network.target" "firewall.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "dnet-nat-start" ''
          ${pkgs.iptables}/bin/iptables -t nat -I PREROUTING -i ${cfg.externalInterface} -p udp --dport 53 -j DNAT --to-destination ${cfg.ip}
          ${pkgs.iptables}/bin/iptables -t nat -I POSTROUTING -s ${cfg.cidr} -o ${cfg.externalInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/iptables -I FORWARD -d ${cfg.ip} -p udp --dport 53 -j ACCEPT
          ${pkgs.iptables}/bin/iptables -I FORWARD -s ${cfg.ip} -p udp --sport 53 -j ACCEPT
        '';
        ExecStop = pkgs.writeShellScript "dnet-nat-stop" ''
          ${pkgs.iptables}/bin/iptables -t nat -D PREROUTING -i ${cfg.externalInterface} -p udp --dport 53 -j DNAT --to-destination ${cfg.ip} || true
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${cfg.cidr} -o ${cfg.externalInterface} -j MASQUERADE || true
          ${pkgs.iptables}/bin/iptables -D FORWARD -d ${cfg.ip} -p udp --dport 53 -j ACCEPT || true
          ${pkgs.iptables}/bin/iptables -D FORWARD -s ${cfg.ip} -p udp --sport 53 -j ACCEPT || true
        '';
      };
    };

    systemd.services.dnet-core = {
      description = "DNet-core User Space Network Stack";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "dnet-init" ''
          ${pkgs.coreutils}/bin/mkdir -p /dev/net
          if [ ! -c /dev/net/tap ]; then
            ${pkgs.coreutils}/bin/mknod /dev/net/tap c 10 200 || true
          fi
          ${pkgs.coreutils}/bin/chmod 666 /dev/net/tap
        '';
        ExecStart = "${dnet-core}/bin/dnet-core dnet0 1280 11:45:14:19:19:81 ${cfg.ip} ${cfg.netmask}";
        Restart = "always";
      };
      postStart = ''
        while ! ${pkgs.iproute2}/bin/ip link show dnet0 >/dev/null 2>&1; do sleep 0.1; done
        ${pkgs.iproute2}/bin/ip link set dev dnet0 up
        ${pkgs.iproute2}/bin/ip route replace ${cfg.cidr} dev dnet0
      '';
    };
  };
}
