{ config, lib, pkgs, ... }:

with lib;

let
  secrets = import ../../secrets.nix;
  nodeRegistry = import ../../lib/nodes.nix;

  # Convert node registry to format needed for iBGP mesh
  # Maps logicalName -> { id, host (hostname), endpoint, ipv6 }
  nodesByLogicalName = listToAttrs (map (hostname:
    let node = nodeRegistry.nodes.${hostname};
    in nameValuePair node.logicalName {
      id = node.id;
      host = hostname;
      endpoint = node.deployment.targetHost;
      ipv6 = head node.dn42.ipv6.addresses;  # Get IPv6 from registry
    }
  ) (attrNames nodeRegistry.nodes));

  hosts = attrNames nodesByLogicalName;

  # Determine my name based on DN42 IPv6
  myIpv6 = head config.networking.dn42.ipv6.addresses;
  myName = head (filter (n: nodesByLogicalName.${n}.ipv6 == myIpv6) hosts);

  # Filter out myself
  otherHosts = filter (n: n != myName) hosts;

  # Generate peer config
  genPeer = name:
    let
      addr = nodesByLogicalName.${name}.endpoint;
      port = toString (10000 + nodesByLogicalName.${myName}.id);
      # Check if address is IPv6 (contains multiple colons)
      isIpv6 = builtins.match ".*:.*:.*" addr != null;
      formattedEndpoint = if isIpv6 then "[${addr}]:${port}" else "${addr}:${port}";
    in {
      asn = nodeRegistry.asn;
      listenPort = 10000 + nodesByLogicalName.${name}.id;
      privateKey = secrets."key_${replaceStrings ["-"] ["_"] myName}";
      publicKey = secrets."key_${replaceStrings ["-"] ["_"] name}_pub";
      endpoint = formattedEndpoint;
      ipv6 = {
        local = myIpv6;
        remote = nodesByLogicalName.${name}.ipv6;
      };
    };

in
{
  config = mkIf (config.networking.dn42.useDnet) {
    networking.dn42.ibgpPeers = listToAttrs (map (n: nameValuePair n (genPeer n)) otherHosts);
  };
}
