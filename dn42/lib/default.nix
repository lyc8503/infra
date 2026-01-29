# DN42 Network Constants and Configuration
# Re-exports from centralized node registry for backward compatibility
let
  nodeRegistry = import ./nodes.nix;
in
{
  # Network Identity
  inherit (nodeRegistry) asn domain;

  # IPv4 Ranges
  ipv4 = {
    inherit (nodeRegistry.anycast) ipv4;
    anycast = nodeRegistry.anycast.ipv4;
    range = nodeRegistry.ipv4Range;
  };

  # IPv6 Ranges
  ipv6 = {
    inherit (nodeRegistry.anycast) ipv6;
    anycast = nodeRegistry.anycast.ipv6;
    range = nodeRegistry.ipv6Range;
  };

  # Looking Glass Servers (auto-generated from node registry)
  lookingGlassServers = map (name: "${name}.r2.dn42") (builtins.attrNames nodeRegistry.nodes);

  # Node Information (simplified view for backward compatibility)
  nodes = builtins.mapAttrs (name: node: {
    inherit (node) location provider logicalName;
  }) nodeRegistry.nodes;

  # Re-export full node registry
  inherit (nodeRegistry) nodeRegistry;
}
