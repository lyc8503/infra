# homelab-nixos

❄️My nix config for homelab

## Installation process

In live cd:

```
nix --option substituters "https://mirror.nju.edu.cn/nix-channels/store" --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko disk-config.nix

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
https://lantian.pub/article/modify-computer/nixos-low-ram-vps.lantian/  

