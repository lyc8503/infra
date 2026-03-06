# Node Configuration Builder
# Auto-generates host configurations from centralized node registry
{ lib, pkgs, ... }:

let
  nodeRegistry = import ./nodes.nix;
  secrets = import ../secrets.nix;
  defaults = import ./defaults.nix { inherit lib secrets nodeRegistry; };

  # Generate complete DN42 network configuration from node metadata
  mkDn42Config = nodeName: let
    node = nodeRegistry.nodes.${nodeName};
  in {
    networking.dn42 = {
      useDnet = true;
      asn = nodeRegistry.asn;
      ipv4 = node.dn42.ipv4;
      ipv6 = node.dn42.ipv6;
    };

    services.dnet-core = lib.mkIf (node.dnet or null != null) {
      enable = true;
      ip = node.dnet.address;
      netmask = node.dnet.netmask;
      cidr = node.dnet.cidr;
    };
  };

  # Generate service configurations with defaults + node overrides
  mkServiceConfig = nodeName: let
    node = nodeRegistry.nodes.${nodeName};
    nodeServices = node.services or {};

    # Base services that are always defined
    baseServices = {
      # Metrics (enabled for all nodes)
      metrics = defaults.metrics;

      # Looking glass (enabled for all nodes)
      dn42-looking-glass = defaults.lookingGlass // {
        servers = lib.mapAttrsToList (name: n: n.logicalName) nodeRegistry.nodes;
      };

      # FRP Server (enabled for all nodes by default)
      frps = defaults.frps;

      # Xjbcast (only for anycast nodes)
      xjbcast = lib.mkIf (nodeServices.xjbcast.enable or false) (
        defaults.xjbcast // {
          enable = true;
          nodeName = node.logicalName;
        }
      );

      # Tor Relay (only if enabled)
      tor-relay = lib.mkIf (nodeServices.tor-relay.enable or false) {
        enable = true;
        nickname = secrets.tor.${node.logicalName}.nickname;
        contactInfo = secrets.tor.contact;
        monthlyLimitGB = nodeServices.tor-relay.monthlyLimitGB or 750;
      };

      # Anchor IP policy routing
      anchor-routing = lib.mkIf (nodeServices.anchor-routing or null != null) {
        enable = true;
        anchorIPv4 = nodeServices.anchor-routing.anchorIPv4;
        ipv4Gateway = nodeServices.anchor-routing.ipv4Gateway;
        extraIPv6 = nodeServices.anchor-routing.extraIPv6 or null;
      };

      # Tcpdump (only if enabled)
      tcpdump = lib.mkIf (nodeServices.tcpdump.enable or false) {
        enable = true;
      };

      # Traffic limit (only if enabled)
      traffic-limit = lib.mkIf (nodeServices.traffic-limit.enable or false) {
        enable = true;
        limitGB = nodeServices.traffic-limit.limitGB or null;
        dryRun = nodeServices.traffic-limit.dryRun or false;
        checkInterval = nodeServices.traffic-limit.checkInterval or "1min";
      };

      # SCX scheduler (controlled per-node, enabled by default in common.nix)
      scx_horoscope = lib.mkIf ((nodeServices.scx_horoscope.enable or null) != null) {
        enable = nodeServices.scx_horoscope.enable;
      };
    };

    # Helper to generate proxy config
    # lookupName: key in nodeServices (nodes.nix); outputName: NixOS service option suffix (my-<outputName>)
    mkProxyConfig = lookupName: outputName: defaultParams: let
      config = nodeServices.${lookupName} or null;
      # Anchor IPs for proxy registration source binding (decoupled from Tor).
      # curl uses --interface so the sub server detects the Reserved/Floating IP.
      anchorIPv4 = nodeServices.anchor-routing.anchorIPv4 or null;
      anchorIPv6 = nodeServices.anchor-routing.extraIPv6 or null;
    in
      lib.optionalAttrs (config != null) {
        "my-${outputName}" = lib.recursiveUpdate defaultParams {
          registration.subId = config.subId or node.hostname;
          registration.ipv4 = config.ipv4 or defaultParams.registration.ipv4;
          registration.ipv6 = config.ipv6 or defaultParams.registration.ipv6;
          registration.traffic = config.traffic;
          registration.srcIpv4 = anchorIPv4;
          registration.srcIpv6 = anchorIPv6;
        };
      };

    # Optional proxy services
    xrayService = mkProxyConfig "xray" "xray-vision-reality" defaults.proxy.xray-vision-reality;
    xrayVmessService = mkProxyConfig "xray-vmess" "xray-vmess" defaults.proxy.xray-vmess;
    hysteriaService = mkProxyConfig "hysteria" "hysteria" defaults.proxy.hysteria;
  in {
    services = baseServices // xrayService // xrayVmessService // hysteriaService;
  };

  # Generate system configuration
  mkSystemConfig = nodeName: let
    node = nodeRegistry.nodes.${nodeName};
  in {
    system.stateVersion = defaults.system.stateVersion;
    networking = {
      hostName = node.hostname;
      usePredictableInterfaceNames = defaults.system.networking.usePredictableInterfaceNames;
      networkmanager.enable = defaults.system.networking.networkmanager.enable;
    };
  };

  # Generate deployment configuration for Colmena
  mkDeploymentConfig = nodeName: let
    node = nodeRegistry.nodes.${nodeName};
  in {
    deployment = node.deployment;
  };

  # Generate complete profile by combining all configurations
  mkProfile = nodeName: let
    nodeServices = nodeRegistry.nodes.${nodeName}.services or {};
  in {
    imports = [
      # Core modules for all nodes
      ../modules/system/common.nix
      ../modules/core/dn42.nix
      ../modules/core/ibgp-full-mesh.nix
      ../modules/services/looking-glass.nix
      ../modules/services/metrics.nix
      ../modules/services/frps.nix
      ../modules/services/smokeping.nix

      # Optional modules
      ../modules/system/tcpdump.nix
      ../modules/system/anchor-routing.nix
      ../modules/system/tor-relay.nix
      ../modules/system/traffic-limit.nix
    ] ++ lib.optionals (nodeServices.xray or null != null) [
      ../modules/proxy/xray-vision-reality.nix
    ] ++ lib.optionals (nodeServices.xray-vmess or null != null) [
      ../modules/proxy/xray-vmess.nix
    ] ++ lib.optionals (nodeServices.hysteria or null != null) [
      ../modules/proxy/hysteria.nix
    ];

    # Combine all auto-generated configs
    inherit (mkSystemConfig nodeName) system;
    inherit (mkDeploymentConfig nodeName) deployment;

    # Merge services from both mkServiceConfig and mkDn42Config
    services = lib.mkMerge [
      (mkServiceConfig nodeName).services
      (mkDn42Config nodeName).services or {}
    ];

    # Merge networking configs carefully (DN42 + system)
    networking = lib.mkMerge [
      (mkDn42Config nodeName).networking
      (mkSystemConfig nodeName).networking
    ];
  };

in
{
  # Export functions
  inherit mkDn42Config mkServiceConfig mkSystemConfig mkDeploymentConfig mkProfile;

  # Export node registry for use in other modules
  inherit nodeRegistry;
}
