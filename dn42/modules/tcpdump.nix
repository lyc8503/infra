{ config, pkgs, lib, ... }:

{
  systemd.services.tcpdump-all = {
    description = "Continuous tcpdump on all interfaces";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /root/dumps";
      # -i any: Listen on all interfaces
      # -C 256: File size limit 256MB
      # -W 10: Keep 10 files
      # -w ...: Output file base name
      # -Z root: Run as root
      ExecStart = "${pkgs.tcpdump}/bin/tcpdump -i any -C 256 -W 10 -w '/root/dumps/capture.pcap' -Z root 'not port 22 and not port 443'";
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
