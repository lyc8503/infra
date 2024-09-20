# homelab-nixos

❄️My nix config for homelab

## Installation process

In live cd:

```
wipefs -a /dev/sda
(echo g; echo n; echo ""; echo ""; echo +1G; echo ""; echo n; echo ""; echo ""; echo ""; echo ""; echo t; echo 1; echo 1; echo w) | fdisk /dev/sda

mkfs.fat -F 32 -n boot /dev/sda1

zpool create -o ashift=13 -O mountpoint=none -O encryption=on -O keylocation=prompt -O keyformat=passphrase pool /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part2

zfs create pool/nix
zfs create pool/persist

mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,nix,persist}
mount /dev/sda1 /mnt/boot
mount -t zfs -o zfsutil pool/nix /mnt/nix
mount -t zfs -o zfsutil pool/persist /mnt/persist

nixos-generate-config --root /mnt
# Copy paste this repo, replace all
nixos-install --no-root-passwd --root /mnt --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
umount -Rl /mnt
zpool export -a
```

## Reference

https://nixos-and-flakes.thiscute.world/zh/nixos-with-flakes/get-started-with-nixos  
https://lantian.pub/article/modify-computer/nixos-impermanence.lantian/  
https://carlosvaz.com/posts/installing-nixos-with-root-on-tmpfs-and-encrypted-zfs-on-a-netcup-vps/
