# Helper functions for DN42 configuration
{ lib, ... }:

{
  # Generate Wireguard peer configuration
  mkWgPeer = { endpoint, publicKey, allowedIPs, persistentKeepalive ? 25 }: {
    inherit endpoint publicKey allowedIPs persistentKeepalive;
  };

  # Generate BGP peer configuration
  mkBgpPeer = { asn, ip, ip6 ? null, multihop ? false }: {
    inherit asn ip;
  } // lib.optionalAttrs (ip6 != null) { inherit ip6; }
    // lib.optionalAttrs multihop { inherit multihop; };

  # Get logical name from hostname
  getLogicalName = hostname: nodes:
    if nodes ? ${hostname}
    then nodes.${hostname}.logicalName
    else hostname;
}
