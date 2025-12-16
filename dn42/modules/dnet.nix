{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnet-core;
  
  dnet-core = pkgs.stdenv.mkDerivation {
    pname = "dnet-core";
    version = "0.0.1-unstable-2025-12-16";

    src = pkgs.fetchFromGitHub {
      owner = "lyc8503";
      repo = "DNet-core";
      rev = "5b54082300c1f95bc1fe8c772209d7bb305ccd22";
      sha256 = "sha256-7G/GSyGEBPPPYx2rMXTF8B/AzHGHVMstbIq4WM+DyHM=";
    };

    nativeBuildInputs = [ pkgs.cmake ];

    postPatch = ''
      substituteInPlace main.cpp \
        --replace 'DNet dnet("dnet0", 1500, "10.0.0.0", "255.255.255.0");' \
                  'DNet dnet("dnet0", 1500, "${cfg.ip}", "${cfg.netmask}");'
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp DNet $out/bin/dnet-core
    '';
  };
in
{
  options.services.dnet-core = {
    enable = mkEnableOption "DNet-core service";
    ip = mkOption {
      type = types.str;
      description = "IP address/Network address for DNet-core";
    };
    netmask = mkOption {
      type = types.str;
      description = "Netmask for DNet-core";
    };
    cidr = mkOption {
      type = types.str;
      description = "CIDR for route (e.g. 172.20.42.224/27)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.dnet-core = {
      description = "DNet-core User Space Network Stack";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /dev/net"
          "-${pkgs.coreutils}/bin/mknod /dev/net/tap c 10 200"
          "${pkgs.coreutils}/bin/chmod 666 /dev/net/tap"
        ];
        ExecStart = "${dnet-core}/bin/dnet-core";
        Restart = "always";
      };
      postStart = ''
        while ! ${pkgs.iproute2}/bin/ip link show dnet0 >/dev/null 2>&1; do sleep 0.1; done
        ${pkgs.iproute2}/bin/ip link set dev dnet0 up
        ${pkgs.iproute2}/bin/ip route replace ${cfg.cidr} dev dnet0
      '';
    };
  };
}
