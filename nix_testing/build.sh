nix run github:nix-community/nixos-generators -- -f lxc | tee /tmp/nixos-build.log

BUILD_OUTPUT="$(tail -n 1 /tmp/nixos-build.log)"
echo "Build output: $BUILD_OUTPUT"

echo "Removing old rootfs"
sudo rm -rf rootfs

echo "Extracting new rootfs"
sudo mkdir rootfs
sudo tar xJf $BUILD_OUTPUT -C rootfs/

echo "=== Starting container ==="
sudo lxc-start -n nix-testing -F
sudo systemd-nspawn -b -D rootfs
