# Service Default Configurations
# Provides default settings for all services with ability to override per-node
{ lib, secrets, nodeRegistry }:

{
  # Proxy service defaults (for edge nodes)
  proxy = {
    xray = {
      enable = lib.mkDefault true;
      uuid = secrets.proxy.uuid;
      visionPort = 23389;
      realityDest = "software.download.prss.microsoft.com:443";
      realityPrivateKey = secrets.proxy.reality_sk;
      realityShortIds = secrets.proxy.short_ids;
      registration = {
        enable = lib.mkDefault true;
        subServer = secrets.proxy.sub_server;
        regPassword = secrets.proxy.reg_password;
        # subId should be overridden per-node
        realityPublicKey = secrets.proxy.reality_pk;
        ipv4 = lib.mkDefault true;
        ipv6 = lib.mkDefault false;
      };
    };

    hysteria = {
      enable = lib.mkDefault true;
      port = 61145;
      password = secrets.proxy.uuid;
      registration = {
        enable = lib.mkDefault true;
        subServer = secrets.proxy.sub_server;
        regPassword = secrets.proxy.reg_password;
        # subId should be overridden per-node
        ipv4 = lib.mkDefault true;
        ipv6 = lib.mkDefault false;
      };
    };
  };

  # Metrics defaults (for all nodes)
  metrics = {
    enable = lib.mkDefault true;
    push_endpoint = secrets.push_endpoint;
    loki_endpoint = secrets.loki_endpoint;
  };

  # Looking glass defaults
  lookingGlass = {
    enable = lib.mkDefault true;
    # servers list will be auto-generated from node registry
    domain = "dn42.42420167.xyz";
  };

  # Xjbcast defaults (for anycast nodes)
  xjbcast = {
    enable = lib.mkDefault false;  # Only enabled for anycast nodes
    # nodeName will be set from node metadata
    ipv4Address = nodeRegistry.anycast.ipv4;
    ipv6Address = nodeRegistry.anycast.ipv6;
  };

  # FRP Server defaults (for all nodes)
  frps = {
    enable = lib.mkDefault true;
  };

  # System defaults
  system = {
    stateVersion = "25.11";
    networking = {
      usePredictableInterfaceNames = false;
      networkmanager.enable = lib.mkDefault true;
    };
  };
}
