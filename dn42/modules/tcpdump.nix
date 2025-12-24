{ config, pkgs, lib, ... }:

let
  cleanupScript = pkgs.writeShellScript "tcpdump-cleanup" ''
    ${pkgs.findutils}/bin/find /root/dumps -name "capture-*.pcap" -type f -printf '%T@ %p\n' | \
      ${pkgs.coreutils}/bin/sort -n | \
      ${pkgs.coreutils}/bin/head -n -10 | \
      ${pkgs.coreutils}/bin/cut -d' ' -f2- | \
      ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm -f
  '';
in
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
      # -G 86400: Rotate at least once a day (required to enable strftime in -w)
      # -w ...: Output file with timestamp
      # -z ...: Run cleanup script after rotation
      # -Z root: Run as root
      ExecStart = "${pkgs.tcpdump}/bin/tcpdump -i any -C 256 -G 86400 -w '/root/dumps/capture-%%Y-%%m-%%d_%%H:%%M:%%S.pcap' -z ${cleanupScript} -Z root";
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
