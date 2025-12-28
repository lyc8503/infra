{ config, lib, pkgs, modulesPath, ... }:

{
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    configurationLimit = 10;
  };

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.kernelPackages = pkgs.linuxPackages_testing;
  
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
}
