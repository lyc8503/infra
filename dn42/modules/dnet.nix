{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnet-core;
  
  dnet-core = pkgs.stdenv.mkDerivation {
    pname = "dnet-core";
    version = "0.0.1-unstable-2025-12-17";

    src = pkgs.fetchFromGitHub {
      owner = "lyc8503";
      repo = "DNet-core";
      rev = "5dd63c626f22d4cef6eb1c9f46ebadba3b6ef678";
      sha256 = "sha256-25rDvvkjQUin50c9+UWiailO+4wiu19iobBnQ2wqybY=";
    };

    nativeBuildInputs = [ pkgs.cmake ];

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
        ExecStart = "${dnet-core}/bin/dnet-core dnet0 1280 11:45:14:19:19:81 ${cfg.ip} ${cfg.netmask}";
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
