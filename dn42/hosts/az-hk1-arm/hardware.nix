{ config, lib, pkgs, modulesPath, ... }:

{
  boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" "virtio_pci" "hv_storvsc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.compressor = "zstd";

  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  fileSystems."/" =
    { device = "/dev/sda2";
      fsType = "ext4";
    };

  fileSystems."/efi" =
    { device = "/dev/sda1";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  virtualisation.hypervGuest.enable = true;
}
