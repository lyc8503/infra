{ config, lib, pkgs, ... }:

with lib;

let
  nodeRegistry = import ../../lib/nodes.nix;
  
  # Extract endpoint host (remove port), handling both IPv4 and IPv6
  extractHost = endpoint: 
    let
      # Check if it's an IPv6 address (starts with [)
      isIPv6 = lib.hasPrefix "[" endpoint;
    in
      if isIPv6 then
        # For IPv6: extract between [ and ]
        let
          withoutBracket = lib.removePrefix "[" endpoint;
          parts = lib.splitString "]" withoutBracket;
        in
          builtins.head parts
      else
        # For IPv4/hostname: split by : and take first part
        let
          parts = lib.splitString ":" endpoint;
        in
          builtins.head parts;
  
  # Process peers and generate target configurations
  peerTargets = 
    let
      externalPeers = config.networking.dn42.peers or {};
      ibgpPeers = config.networking.dn42.ibgpPeers or {};
      
      # Process eBGP peers - use ASN last 4 digits as name
      ebgpTargets = mapAttrsToList (name: peer:
        let
          host = extractHost peer.endpoint;
          # Get last 4 digits of ASN
          asnStr = toString peer.asn;
          asnLen = stringLength asnStr;
          asnLast4 = substring (asnLen - 4) 4 asnStr;
        in
          {
            name = "DN42_${asnLast4}";
            host = host;
            title = "DN42 ${asnLast4} (${host})";
          }
      ) externalPeers;
      
      # Process iBGP peers - use logicalName
      ibgpTargets = mapAttrsToList (name: peer:
        let
          host = extractHost peer.endpoint;
          # Find the node with matching endpoint to get logicalName
          matchingNode = lib.findFirst 
            (nodeName: 
              let node = nodeRegistry.nodes.${nodeName};
              in (node.publicIpv4 or "") == host || (node.publicIpv6 or "") == host
            )
            null
            (attrNames nodeRegistry.nodes);
          logicalName = if matchingNode != null 
            then nodeRegistry.nodes.${matchingNode}.logicalName 
            else name;
        in
          {
            name = logicalName;
            host = host;
            title = "${logicalName} iBGP (${host})";
          }
      ) ibgpPeers;
      
      # Combine all targets
      allTargets = ebgpTargets ++ ibgpTargets;
      
      # Remove duplicates by host
      uniqueTargets = lib.unique allTargets;
    in
      uniqueTargets;
  
  # Generate smokeping target configuration string
  generateTargetConfig = targets:
    concatStringsSep "\n" (map (target: ''
      ++ ${target.name}
      menu = ${target.title}
      title = ${target.title}
      host = ${target.host}
    '') targets);

in
{
  # Use NixOS's built-in smokeping service
  config = mkIf (peerTargets != []) {
    services.smokeping = {
      enable = true;
      owner = "SmokePing DN42";
      hostName = config.networking.hostName;
      databaseConfig = ''
        step     = 60
        pings    = 10
        
        # consfn mrhb steps total
        AVERAGE  0.5   1  5040
        AVERAGE  0.5  60  4320
            MIN  0.5  60  4320
            MAX  0.5  60  4320
        AVERAGE  0.5 720   720
            MAX  0.5 720   720
            MIN  0.5 720   720
      '';
      
      presentationConfig = ''
        + charts
        
        menu = Charts
        title = The most interesting destinations
        
        ++ stddev
        sorter = StdDev(entries=>4)
        title = Top Standard Deviation
        menu = Std Deviation
        format = Standard Deviation %f
        
        ++ max
        sorter = Max(entries=>5)
        title = Top Max Roundtrip Time
        menu = by Max
        format = Max Roundtrip Time %f seconds
        
        ++ loss
        sorter = Loss(entries=>5)
        title = Top Packet Loss
        menu = Loss
        format = Packets Lost %f
        
        ++ median
        sorter = Median(entries=>5)
        title = Top Median Roundtrip Time
        menu = by Median
        format = Median RTT %f seconds
        
        + overview
        
        width = 600
        height = 50
        range = 10h
        
        + detail
        
        width = 600
        height = 200
        unison_tolerance = 2
        
        "Last 3 Hours"    3h
        "Last 30 Hours"   30h
        "Last 10 Days"    10d
        "Last 360 Days"   360d
      '';
      
      probeConfig = ''
        + FPing
        binary = ${pkgs.fping}/bin/fping
      '';
      
      targetConfig = ''
        probe = FPing
        
        menu = Top
        title = Network Latency Grapher
        remark = Welcome to the SmokePing website of DN42 Network.
        
        + DN42Peers
        menu = DN42 Peers
        title = DN42 Peer Endpoints (External + iBGP)
        
        ${generateTargetConfig peerTargets}
      '';
    };
    
    # Configure nginx to serve smokeping on port 5001
    services.nginx.virtualHosts.smokeping = {
      listen = [
        { addr = "0.0.0.0"; port = 5001; }
        { addr = "[::]"; port = 5001; }
      ];
    };
  };
}

