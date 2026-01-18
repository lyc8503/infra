{ config, lib, pkgs, ... }:

with lib;

let
  secrets = import ../secrets.nix;
  
  # Define metadata for all nodes
  # Node Name -> { id, host (hostname), endpoint (physical IP/domain) }
  nodes = {
    ams1 = { id = 1; host = "do-ams1"; endpoint = "2001:bc8:1640:4f16:f5bf:e8bf:fd1d:e65a"; };
    sfo1 = { id = 2; host = "do-sfo1"; endpoint = "146.190.12.5"; };
    sgp1 = { id = 3; host = "neo-misc"; endpoint = secrets.misc_endpoint; };
    chs1 = { id = 6; host = "gcp-chs1"; endpoint = secrets.gcp_chs1_ip; };
    sgp2 = { id = 8; host = "az-sg-1-ats"; endpoint = secrets.az_sg1_ip; };
    hkg1 = { id = 9; host = "az-hk-1-arm"; endpoint = secrets.az_hk1_arm_ip; };
  };
  
  hosts = attrNames nodes;
  
  # Helper to get config of another host
  getHostConfig = name: 
    let 
      confName = if (nodes.${name} ? logic && !nodes.${name}.logic) then nodes.${name}.host else name;
    in import ../conf42/${confName}.nix { inherit pkgs lib; config = {}; };
  
  # Get all host configs
  hostConfigs = genAttrs hosts getHostConfig;

  # Determine my name based on DN42 IPv6
  myIpv6 = head config.networking.dn42.ipv6.addresses;
  myName = head (filter (n: head hostConfigs.${n}.networking.dn42.ipv6.addresses == myIpv6) hosts);
  
  # Filter out myself
  otherHosts = filter (n: n != myName) hosts;

  # Generate peer config
  genPeer = name: {
    asn = 4242420167;
    listenPort = 10000 + nodes.${name}.id;
    privateKey = secrets."key_${replaceStrings ["-"] ["_"] myName}";
    publicKey = secrets."key_${replaceStrings ["-"] ["_"] name}_pub";
    endpoint = "${nodes.${name}.endpoint}:${toString (10000 + nodes.${myName}.id)}";
    ipv6 = {
      local = head config.networking.dn42.ipv6.addresses;
      remote = head hostConfigs.${name}.networking.dn42.ipv6.addresses;
    };
  };

in
{
  config = mkIf (config.networking.dn42.useDnet) {
    networking.dn42.ibgpPeers = listToAttrs (map (n: nameValuePair n (genPeer n)) otherHosts);
  };
}
