{ config, lib, pkgs, ... }:

with lib;

let
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

      ipv4 = {
        local = mkOption { type = types.str; description = "Local IPv4 PtP address"; };
        remote = mkOption { type = types.str; description = "Remote IPv4 PtP address"; };
      };
    };
  };

  birdBaseConfig = ''
    ################################################
    #               Variable header                #
    ################################################

    define OWNAS = 4242420167;
    define OWNIP = 172.20.42.224;
    define OWNIPv6 = fd00:1100:8503::1;
    define OWNNET = 172.20.42.224/27;
    define OWNNETv6 = fd00:1100:8503::/48;
    define OWNNETSET = [172.20.42.224/27+];
    define OWNNETSETv6 = [fd00:1100:8503::/48+];

    ################################################
    #                 Header end                   #
    ################################################

    router id OWNIP;

    protocol device {
        scan time 10;
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
  '';
in
{
  options.networking.dn42.peers = mkOption {
    type = types.attrsOf (types.submodule peerOptions);
    default = {};
    description = "DN42 peers configuration";
  };

  config = mkIf (config.networking.dn42.peers != {}) {
    services.bird.enable = true;
    services.bird.package = pkgs.bird2;
    networking.wireguard.interfaces = mapAttrs' (name: peer: 
      nameValuePair "dn42_${name}" {
        listenPort = peer.listenPort;
        privateKey = peer.privateKey;
        
        postSetup = ''
          ${pkgs.iproute2}/bin/ip addr add ${peer.ipv6.local} peer ${peer.ipv6.remote} dev dn42_${name}
          ${pkgs.iproute2}/bin/ip addr add ${peer.ipv4.local} peer ${peer.ipv4.remote} dev dn42_${name}
          ${pkgs.procps}/bin/sysctl -w net.ipv6.conf.dn42_${name}.autoconf=0
        '';

        peers = [
          {
            publicKey = peer.publicKey;
            endpoint = peer.endpoint;
            allowedIPs = [ "10.0.0.0/8" "172.20.0.0/14" "172.31.0.0/16" "fd00::/8" "fe80::/64" ];
          }
        ];
      }
    ) config.networking.dn42.peers;

    services.bird.config = birdBaseConfig + "\n" + (concatStringsSep "\n" (mapAttrsToList (name: peer: ''
      protocol bgp dn42_${name} from dnpeers {
          enable extended messages on;
          neighbor ${peer.ipv6.remote}%dn42_${name} as ${toString peer.asn};
          ipv4 {
              extended next hop on;
          };
      };
    '') config.networking.dn42.peers));
  };
}
