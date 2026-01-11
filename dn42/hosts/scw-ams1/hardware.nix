{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "virtio_scsi" "virtio_blk" "ahci" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  fileSystems."/" =
    { device = "/dev/vda2";
      fsType = "ext4";
    };

  fileSystems."/efi" =
    { device = "/dev/vda1";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}