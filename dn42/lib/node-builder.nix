# Node Configuration Builder
# Auto-generates host configurations from centralized node registry
{ lib, pkgs, ... }:

let
  nodeRegistry = import ./nodes.nix;
  secrets = import ../secrets.nix;
  defaults = import ./defaults.nix { inherit lib secrets; };

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
        ipv6 = secrets.tor.${node.logicalName}.ipv6;
        nickname = secrets.tor.${node.logicalName}.nickname;
        contactInfo = secrets.tor.contact;
        publicIPv4 = secrets.tor.${node.logicalName}.ipv4;
        # Optional overrides from node config
        anchorIPv4 = nodeServices.tor-relay.anchorIPv4 or null;
        ipv4Gateway = nodeServices.tor-relay.ipv4Gateway or null;
        monthlyLimitGB = nodeServices.tor-relay.monthlyLimitGB or 750;
      };

      # Tcpdump (only if enabled)
      tcpdump = lib.mkIf (nodeServices.tcpdump.enable or false) {
        enable = true;
      };

      # Traffic limit (only if enabled)
      traffic-limit = lib.mkIf (nodeServices.traffic-limit.enable or false) {
        enable = true;
        limitGB = nodeServices.traffic-limit.limitGB or 180;
        dryRun = nodeServices.traffic-limit.dryRun or false;
        checkInterval = nodeServices.traffic-limit.checkInterval or "1min";
      };

      # SCX scheduler (controlled per-node, enabled by default in common.nix)
      scx_horoscope = lib.mkIf ((nodeServices.scx_horoscope.enable or null) != null) {
        enable = nodeServices.scx_horoscope.enable;
      };
    };

    # Optional proxy services
    xrayService = lib.optionalAttrs ((nodeServices.xray or null) != null) {
      my-xray = lib.recursiveUpdate defaults.proxy.xray {
        registration.subId = nodeServices.xray.subId or node.hostname;
        registration.traffic =
          if nodeServices.xray.traffic or null != null
          then nodeServices.xray.traffic
          else defaults.proxy.xray.registration.traffic;
      };
    };

    hysteriaService = lib.optionalAttrs ((nodeServices.hysteria or null) != null) {
      my-hysteria = lib.recursiveUpdate defaults.proxy.hysteria {
        registration.subId = nodeServices.hysteria.subId or node.hostname;
        registration.traffic =
          if nodeServices.hysteria.traffic or null != null
          then nodeServices.hysteria.traffic
          else defaults.proxy.hysteria.registration.traffic;
      };
    };
  in {
    services = baseServices // xrayService // hysteriaService;
  };

  # Generate system configuration
  mkSystemConfig = nodeName: let
    node = nodeRegistry.nodes.${nodeName};
    nodeServices = node.services or {};
  in {
    system.stateVersion = defaults.system.stateVersion;
    networking = {
      hostName = node.hostname;
      usePredictableInterfaceNames = defaults.system.networking.usePredictableInterfaceNames;

      # WARP configuration
      wg-quick.interfaces = lib.mkIf (nodeServices.warp.enable or false) {
        wg-warp = {
          autostart = true;
          address = nodeServices.warp.address or [ "172.16.0.2/32" ];
          privateKey = secrets.warp.${node.logicalName}.privateKey;
          mtu = 1280;
          peers = [
            {
              publicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
              allowedIPs = nodeServices.warp.allowedIPs or [ "0.0.0.0/0" ];
              endpoint = "engage.cloudflareclient.com:2408";
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };
    networking.networkmanager.enable = defaults.system.networking.networkmanager.enable;
  };

  # Generate deployment configuration for Colmena
  mkDeploymentConfig = nodeName: let
    node = nodeRegistry.nodes.${nodeName};
  in {
    deployment = node.deployment;
  };

  # Generate complete profile by combining all configurations
  mkProfile = nodeName: let
    node = nodeRegistry.nodes.${nodeName};
    nodeServices = node.services or {};
  in {
    imports = [
      # Core modules for all nodes
      ../modules/system/common.nix
      ../modules/core/dn42.nix
      ../modules/core/ibgp-full-mesh.nix
      ../modules/services/looking-glass.nix
      ../modules/services/metrics.nix

      # Optional modules
      ../modules/system/tcpdump.nix
      ../modules/system/tor-relay.nix
      ../modules/system/traffic-limit.nix
    ] ++ lib.optionals (nodeServices.xray or null != null) [
      ../modules/proxy/xray.nix
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
