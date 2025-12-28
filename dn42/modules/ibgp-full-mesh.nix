{ config, lib, pkgs, ... }:

with lib;

let
  secrets = import ../secrets.nix;
  
  # Define metadata for all nodes
  nodes = {
    ams1 = { id = 1; endpoint = "ams1.dn42.42420167.xyz"; };
    sfo1 = { id = 2; endpoint = "sfo1.dn42.42420167.xyz"; };
    sgp1 = { id = 3; endpoint = "sgp1.dn42.42420167.xyz"; };
    syd1 = { id = 4; endpoint = "syd1.dn42.42420167.xyz"; };
    tor1 = { id = 5; endpoint = "tor1.dn42.42420167.xyz"; };
    lon1 = { id = 6; endpoint = "lon1.dn42.42420167.xyz"; };
  };
  
  hosts = attrNames nodes;
  
  # Helper to get config of another host
  getHostConfig = name: import ../conf42/${name}.nix { inherit pkgs lib; config = {}; };
  
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
    privateKey = secrets."key_do_${myName}";
    publicKey = secrets."key_do_${name}_pub";
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
