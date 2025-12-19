{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking.dn42;

  peerOptions = { name, config, ... }: {
    options = {
      asn = mkOption {
        type = types.int;
        description = "Peer ASN";
      };

      listenPort = mkOption {
        type = types.int;
        description = "Wireguard listen port";
      };

      privateKey = mkOption {
        type = types.str;
        description = "Wireguard private key";
      };

      publicKey = mkOption {
        type = types.str;
        description = "Peer Wireguard public key";
      };

      endpoint = mkOption {
        type = types.str;
        description = "Peer Wireguard endpoint";
      };

      ipv6 = {
        local = mkOption { type = types.str; description = "Local IPv6 link-local address"; };
        remote = mkOption { type = types.str; description = "Remote IPv6 link-local address"; };
      };

      ipv4 = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            local = mkOption { type = types.str; description = "Local IPv4 PtP address"; };
            remote = mkOption { type = types.str; description = "Remote IPv4 PtP address"; };
          };
        });
        default = null;
        description = "IPv4 PtP configuration";
      };
    };
  };

  birdBaseConfig = ''
    ################################################
    #               Variable header                #
    ################################################

    define OWNAS = ${toString cfg.asn};
    define OWNIP = ${cfg.ipv4.address};
    define OWNIPv6 = ${cfg.ipv6.address};
    define OWNNET = ${cfg.ipv4.network};
    define OWNNETv6 = ${cfg.ipv6.network};
    define OWNNETSET = [${cfg.ipv4.network}+];
    define OWNNETSETv6 = [${cfg.ipv6.network}+];

    ################################################
    #                 Header end                   #
    ################################################

    router id OWNIP;

    protocol device {
        scan time 10;
    }

    protocol direct {
        ipv4;
        ipv6;
        ${if config.networking.dn42.useDnet then ''interface "dn42dummy0"; interface "dnet0";'' else ''interface "dn42dummy0";''}
    }

    /*
     *  Utility functions
     */

    function is_self_net() -> bool {
      return net ~ OWNNETSET;
    }

    function is_self_net_v6() -> bool {
      return net ~ OWNNETSETv6;
    }

    function is_valid_network() -> bool {
      return net ~ [
        172.20.0.0/14{21,29}, # dn42
        172.20.0.0/24{28,32}, # dn42 Anycast
        172.21.0.0/24{28,32}, # dn42 Anycast
        172.22.0.0/24{28,32}, # dn42 Anycast
        172.23.0.0/24{28,32}, # dn42 Anycast
        172.31.0.0/16+,       # ChaosVPN
        10.100.0.0/14+,       # ChaosVPN
        10.127.0.0/16+,       # neonetwork
        10.0.0.0/8{15,24}     # Freifunk.net
      ];
    }

    #roa4 table dn42_roa;
    #roa6 table dn42_roa_v6;

    #protocol static {
    #    roa4 { table dn42_roa; };
    #    include "/etc/bird/roa_dn42.conf";
    #};

    #protocol static {
    #    roa6 { table dn42_roa_v6; };
    #    include "/etc/bird/roa_dn42_v6.conf";
    #};

    function is_valid_network_v6() -> bool {
      return net ~ [
        fd00::/8{44,64} # ULA address space as per RFC 4193
      ];
    }

    protocol kernel {
        scan time 20;

        ipv6 {
            import none;
            export filter {
                if source = RTS_STATIC then reject;
                krt_prefsrc = OWNIPv6;
                accept;
            };
        };
    };

    protocol kernel {
        scan time 20;

        ipv4 {
            import none;
            export filter {
                if source = RTS_STATIC then reject;
                krt_prefsrc = OWNIP;
                accept;
            };
        };
    }

    protocol static {
        route OWNNET reject;
        ${if cfg.useDnet then "route ${cfg.ipv4.dnetAddress}/32 via \"dnet0\";" else ""}

        ipv4 {
            import all;
            export none;
        };
    }

    protocol static {
        route OWNNETv6 reject;

        ipv6 {
            import all;
            export none;
        };
    }

    template bgp dnpeers {
        local as OWNAS;
        path metric 1;

        ipv4 {
            import filter {
              if is_valid_network() && !is_self_net() then {
               # if (roa_check(dn42_roa, net, bgp_path.last) != ROA_VALID) then {
                  # Reject when unknown or invalid according to ROA
               #   print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
               #   reject;
               # } else accept;
               accept;
              } else reject;
            };

            export filter { if is_valid_network() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
            import limit 9000 action block;
        };

        ipv6 {   
            import filter {
              if is_valid_network_v6() && !is_self_net_v6() then {
                #if (roa_check(dn42_roa_v6, net, bgp_path.last) != ROA_VALID) then {
                  # Reject when unknown or invalid according to ROA
                #  print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                #  reject;
                #} else accept;
                accept;
              } else reject;
            };
            export filter { if is_valid_network_v6() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
            import limit 9000 action block; 
        };
    }

    template bgp dnpeers_ibgp {
        local as OWNAS;
        path metric 1;
        direct;

        ipv4 {
            import all;
            export all;
            next hop self;
        };

        ipv6 {
            import all;
            export all;
            next hop self;
        };
    }
  '';
in
{
  imports = [ ./dnet.nix ];

  options.networking.dn42 = {
    useDnet = mkEnableOption "Use DNet-core instead of dn42dummy0";
    asn = mkOption {
      type = types.int;
      description = "Autonomous System Number";
    };
    ipv4 = {
      address = mkOption { type = types.str; description = "Host IPv4 Address"; };
      dnetAddress = mkOption { type = types.str; description = "DNET IPv4 Address (used when useDnet)"; };
      network = mkOption { type = types.str; description = "IPv4 Network to announce"; };
    };
    ipv6 = {
      address = mkOption { type = types.str; description = "Host IPv6 Address"; };
      network = mkOption { type = types.str; description = "IPv6 Network to announce"; };
    };
    peers = mkOption {
      type = types.attrsOf (types.submodule peerOptions);
      default = {};
      description = "DN42 peers configuration";
    };
  };

  config = mkIf (cfg.peers != {}) {
    services.bird.enable = true;
    services.bird.package = pkgs.bird2;
    networking.wg-quick.interfaces = mapAttrs' (name: peer: 
      nameValuePair "dn42_${name}" {
        listenPort = peer.listenPort;
        privateKey = peer.privateKey;
        
        # Avoid routing loops and conflicts with BIRD
        table = "off";

        postUp = ''
          ${pkgs.iproute2}/bin/ip addr add ${peer.ipv6.local} peer ${peer.ipv6.remote} dev dn42_${name}
          ${if peer.ipv4 != null then "${pkgs.iproute2}/bin/ip addr add ${peer.ipv4.local} peer ${peer.ipv4.remote} dev dn42_${name}" else ""}
          ${pkgs.procps}/bin/sysctl -w net.ipv6.conf.dn42_${name}.autoconf=0
          ${pkgs.procps}/bin/sysctl -w net.ipv4.conf.dn42_${name}.rp_filter=0  # Otherwise it drops some packets
        '';

        peers = [
          {
            publicKey = peer.publicKey;
            endpoint = peer.endpoint;
            allowedIPs = [ "10.0.0.0/8" "172.20.0.0/14" "172.31.0.0/16" "fd00::/8" "fe80::/64" ];
          }
        ];
      }
    ) cfg.peers;

    networking.interfaces.dn42dummy0 = {
      virtual = true;
      ipv4.addresses = [{
        address = cfg.ipv4.address;
        prefixLength = 32;
      }];
      ipv6.addresses = [{
        address = cfg.ipv6.address;
        prefixLength = 128;
      }];
    };

    services.dnet-core = mkIf cfg.useDnet {
      enable = true;
      ip = cfg.ipv4.dnetAddress;
      netmask = "255.255.255.255";
      cidr = "${cfg.ipv4.dnetAddress}/32";
    };

    boot.kernel.sysctl = {
      "net.ipv4.conf.dn42dummy0.rp_filter" = "0";
    };

    services.bird.config = birdBaseConfig + "\n" + (concatStringsSep "\n" (mapAttrsToList (name: peer: ''
      protocol bgp dn42_${name} from ${if peer.asn == cfg.asn then "dnpeers_ibgp" else "dnpeers"} {
        enable extended messages on;
        neighbor ${peer.ipv6.remote}%dn42_${name} as ${toString peer.asn};
        ipv4 {
          extended next hop on;
        };
      };
    '') cfg.peers));
  };
}
