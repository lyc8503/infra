{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnet-core;
  
  dnsRecord = pkgs.writeText "DNSRecord.h" ''
    #ifndef DNET_DNS_RECORD_H
    #define DNET_DNS_RECORD_H

    #include "DNS.h"

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
        REGISTER_GENERIC_RECORD(TYPE_NS, "42420167.xyz",
            6,
            "\x03ns3\xc0\x0c"
        );
        REGISTER_A_RECORD("ns1.42420167.xyz", "64.227.99.106");
        REGISTER_A_RECORD("ns2.42420167.xyz", "165.22.195.57");
        REGISTER_A_RECORD("ns3.42420167.xyz", "167.99.65.156");
        REGISTER_A_RECORD("sfo1.dn42.42420167.xyz", "64.227.99.106");
        REGISTER_A_RECORD("ams1.dn42.42420167.xyz", "165.22.195.57");
        REGISTER_A_RECORD("sgp1.dn42.42420167.xyz", "167.99.65.156");
        REGISTER_GENERIC_RECORD(TYPE_AAAA, "v6.sfo1.dn42.42420167.xyz", 16, "\x26\x04\xa8\x80\x00\x04\x01\xd0\x00\x00\x00\x01\x45\x00\x10\x00");
        REGISTER_GENERIC_RECORD(TYPE_AAAA, "v6.ams1.dn42.42420167.xyz", 16, "\x2a\x03\xb0\xc0\x00\x02\x00\xf0\x00\x00\x00\x01\x17\x60\xe0\x01");
        REGISTER_GENERIC_RECORD(TYPE_AAAA, "v6.sgp1.dn42.42420167.xyz", 16, "\x24\x00\x61\x80\x00\x00\x00\xd2\x00\x00\x00\x02\x74\x90\xd0\x00");
    }
    #endif // DNET_DNS_RECORD_H
  '';
  
  dnet-core = pkgs.stdenv.mkDerivation {
    pname = "dnet-core";
    version = "0.0.1-unstable-2025-12-21";

    src = pkgs.fetchFromGitHub {
      owner = "lyc8503";
      repo = "DNet-core";
      rev = "7f7e7b0e40e41723cef0bdef7ac661a7262c8fd0";
      sha256 = "sha256-ZC+zOJQ2adK/Cldh4GJKCtwq6IOq0BeBZlBqzzA/A4Y=";
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
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /dev/net"
          "-${pkgs.coreutils}/bin/mknod /dev/net/tap c 10 200"
          "${pkgs.coreutils}/bin/chmod 666 /dev/net/tap"
        ];
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
