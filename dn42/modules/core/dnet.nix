{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnet-core;
  secrets = import ../../secrets.nix;
  nodeRegistry = import ../../lib/nodes.nix;

  # Helper to convert IPv6 address to hex bytes for AAAA record
  ipv6ToHex = ipv6: let
    pythonScript = pkgs.writeText "ipv6-to-hex.py" ''
      import ipaddress, sys
      addr = ipaddress.IPv6Address(sys.argv[1])
      result = ""
      for b in addr.packed:
        result += "\\x%02x" % b
      print(result, end="")
    '';
  in builtins.readFile (pkgs.runCommand "ipv6-hex-${builtins.replaceStrings [":"] ["-"] ipv6}" {} ''
    ${pkgs.python3}/bin/python3 ${pythonScript} "${ipv6}" > $out
  '');

  # Helper to generate A records for nodes with IPv4
  genNodeARecords = concatStrings (mapAttrsToList (name: node:
    optionalString (node.publicIpv4 or null != null) ''
      REGISTER_A_RECORD("${node.hostname}.dn42.42420167.xyz", "${node.publicIpv4}");
    ''
  ) nodeRegistry.nodes);

  # Helper to generate AAAA records for nodes with IPv6
  genNodeAAAARecords = concatStrings (mapAttrsToList (name: node:
    optionalString (node.publicIpv6 or null != null) ''
      REGISTER_GENERIC_RECORD(TYPE_AAAA, "${node.hostname}.dn42.42420167.xyz", 16, "${ipv6ToHex node.publicIpv6}");
    ''
  ) nodeRegistry.nodes);

  # Helper to generate CNAME records for logical names
  genCNAMERecords = concatStrings (mapAttrsToList (name: node: ''
    REGISTER_CNAME_RECORD("${node.logicalName}.dn42.42420167.xyz", "${node.hostname}.dn42.42420167.xyz");
  '') nodeRegistry.nodes);

  # Helper to generate TXT records for peering info
  genTXTRecords = concatStrings (mapAttrsToList (name: node:
    let
      keyName = replaceStrings ["-"] ["_"] node.logicalName;
      pubKey = secrets."key_${keyName}_pub";
      # All nodes have looking glass and are available for peering
      hasXray = node.services.xray or null != null;
    in ''
      register_txt("${node.logicalName}.dn42.42420167.xyz", "ASN: ${toString nodeRegistry.asn}");
      register_txt("${node.logicalName}.dn42.42420167.xyz", "Endpoint: ${node.logicalName}.dn42.42420167.xyz:2xxxx (xxxx is the last 4 digits of your ASN)");
      register_txt("${node.logicalName}.dn42.42420167.xyz", "IPv6 LLA: fe80::167");
      register_txt("${node.logicalName}.dn42.42420167.xyz", "PubKey: ${pubKey}");
      register_txt("${node.logicalName}.dn42.42420167.xyz", "MP-BGP: enabled");
      register_txt("${node.logicalName}.dn42.42420167.xyz", "Extended Next Hop: enabled");
      register_txt("${node.logicalName}.dn42.42420167.xyz", "Looking Glass: http://${node.logicalName}.dn42.42420167.xyz:5000/");
      ${optionalString hasXray ''register_txt("${node.logicalName}.dn42.42420167.xyz", "Please provide me with your endpoint/port/pubkey/link-local address so I can peer with you!");
      ''}'')  nodeRegistry.nodes);
  
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

        REGISTER_A_RECORD("mail.dn42.42420167.xyz", "188.239.22.57");
        REGISTER_GENERIC_RECORD(TYPE_MX, "dn42.42420167.xyz",
          26,
          "\000\012\004mail\004dn42\01042420167\003xyz\000"
        );

        ${genNodeARecords}
        ${genNodeAAAARecords}
        ${genCNAMERecords}

        auto register_txt = [&](const char* name, const char* text) {
            size_t len = strlen(text);
            char* rdata = new char[len + 1];
            rdata[0] = (char)len;
            memcpy(rdata + 1, text, len);
            REGISTER_GENERIC_RECORD(16, name, len + 1, rdata);
            delete[] rdata;
        };

        ${genTXTRecords}
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
