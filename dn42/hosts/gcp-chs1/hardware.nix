{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "virtio_scsi" "sd_mod" "ahci" "ata_piix" "virtio_pci" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
