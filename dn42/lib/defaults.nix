# Service Default Configurations
# Provides default settings for all services with ability to override per-node
{ lib, secrets }:

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
        traffic = lib.mkDefault 1000;
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
        traffic = lib.mkDefault 1000;
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
    ipv4Address = "172.23.41.81";
    ipv6Address = "fd32:3940:2738::1";
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
