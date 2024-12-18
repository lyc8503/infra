# HomeLab Proxmox VE ansible playbook

## System installation (manual steps)

Tested on: PVE 8.3 graphical installer

First install PVE normally with following config:

```
target_disk = <YOUR DISK>
options/filesystem = zfs (RAID0)
options/ashift = 13 (if SSD)

country = China (or your real location)
timezone = Asia/Shanghai

password = <REMOVED>
email = <YOUR EMAIL>

FQDN = pve.lan
```

---

**[OPTIONAL ENCRYPTION SETUP]** After installation, reboot **with installer ISO**, enter debug mode and run "exit" to get to the shell, execute following commands (to setup zfs encryption and replace `rpool/data` with `rpool/pve`):

```
zpool import -f rpool

zfs destroy rpool/var-lib-vz
zfs destroy rpool/data

zfs snapshot -r rpool/ROOT@copy
zfs send -R rpool/ROOT@copy | zfs recv rpool/copyroot
zfs destroy -r rpool/ROOT

zfs create -o encryption=on -o keyformat=passphrase rpool/ROOT
zfs create -o encryption=on -o keyformat=passphrase rpool/data
zfs create -o encryption=on -o keyformat=passphrase rpool/pve

zfs send -R rpool/copyroot/pve-1@copy | zfs recv -o encryption=on rpool/ROOT/pve-1
zfs destroy -r rpool/copyroot
zfs set mountpoint=/ rpool/ROOT/pve-1

zpool export rpool

# reboot
```

After reboot, you should be prompted to enter your password set just now.

Login into dashboard, remove `local-zfs` in `Datacenter-Storage`, create a new `ZFS` storage with `rpool/pve`

*If you use ZFS-as-root without secure boot, systemd-boot will be selected. Make sure you switch to GRUB before continuing (format boot partition and re-init): [https://pve.proxmox.com/wiki/Host_Bootloader](https://pve.proxmox.com/wiki/Host_Bootloader)*

Setup remote SSH unlock:

```
# Ref: https://github.com/openzfs/zfs/tree/master/contrib/initramfs & https://www.sindastra.de/p/2789/server-encryption-with-remote-ssh-unlock
apt install dropbear-initramfs
apt purge cryptsetup-initramfs
cat << EOF > /etc/dropbear/initramfs/authorized_keys
YOUR_KEY_HERE
EOF
chmod 600 /etc/dropbear/initramfs/authorized_keys

cat << 'EOF' > /usr/share/initramfs-tools/zfsunlockall
if [ ! -e /run/zfs_unlock_complete_notify ]; then
   mkfifo /run/zfs_unlock_complete_notify
fi
while true; do
    pool_pass=$(systemd-ask-password "Encrypted ZFS password for pool:")
    echo $pool_pass | /sbin/zfs load-key rpool/pve
    if [ $? -eq 0 ]; then
        echo "Key loaded successfully."
        break
    else
        echo "Failed to load key. Please try again."
    fi
done

echo $pool_pass | /sbin/zfs load-key rpool/data
echo $pool_pass | /sbin/zfs load-key rpool/ROOT

zfs_console_askpwd_cmd=$(cat /run/zfs_console_askpwd_cmd)
zfs_console_askpwd_pid=$(ps | awk '!'"/awk/ && /$zfs_console_askpwd_cmd/ { print \$1; exit }")
if [ -n "$zfs_console_askpwd_pid" ]; then
    kill "$zfs_console_askpwd_pid"
fi
echo "ok" > /run/zfs_unlock_complete_notify
EOF
chmod 755 /usr/share/initramfs-tools/zfsunlockall

cat << 'EOF' > /usr/share/initramfs-tools/hooks/zfsunlockall
#!/bin/sh

if [ "$1" = "prereqs" ]; then
        echo "dropbear"
        exit
fi

. /usr/share/initramfs-tools/hook-functions

copy_exec /usr/share/initramfs-tools/zfsunlockall /usr/bin/zfsunlockall
EOF
chmod 755 /usr/share/initramfs-tools/hooks/zfsunlockall

echo '' >> /etc/initramfs-tools/initramfs.conf
echo 'IP=192.168.1.10::192.168.1.1:255.255.255.0:homelab-initramfs' >> /etc/initramfs-tools/initramfs.conf

echo '' >> /etc/dropbear/initramfs/dropbear.conf
echo 'IFDOWN="*"' >> /etc/dropbear/initramfs/dropbear.conf
echo 'DROPBEAR_OPTIONS="-p 2222 -j -k -s -c zfsunlockall"' >> /etc/dropbear/initramfs/dropbear.conf

update-initramfs -u
```
---

**[Optional] Intel GVT-g**  

Edit `/etc/default/grub`:  `GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on i915.enable_gvt=1"`  
Run `update-grub` (or `proxmox-boot-tool refresh`)

*GVT-g+Windows guest doesn't work on kernel 6.8.12 SMH, [downgrade](https://forum.proxmox.com/threads/downgrade-kernel-from-6-8-to-6-7.156205/) to 6.8.8 if needed*

Run:
```
echo vfio >> /etc/modules
echo vfio_iommu_type1 >> /etc/modules
echo vfio_pci >> /etc/modules
echo vfio_virqfd >> /etc/modules
echo kvmgt >> /etc/modules
```

Reboot and use `ls /sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/` to validate  

---

## Ansible

Now you can deploy the playbook on the fresh-installed PVE system:

```
ansible-playbook -i inventory.yaml main.yaml
```

Some other manual steps:

- [ ] Restore VM from backup (and make sure they're running correctly)
- [ ] Change APT sources & enterprise license
- [ ] Setup Let's Encrypt SSL & 2FA
- [ ] Setup backup jobs & script
- [ ] Setup SSH Key & Disable password login
- [ ] Enable conservative cpu governor: `cpupower frequency-set -g conservative` (put it in crontab if you like, use `@reboot <command>`)
- [ ] CT Template source: https://mirrors.tuna.tsinghua.edu.cn/help/proxmox/

## Deployment checklist

Maybe reboot before test

- [ ] Test Netdata dashboard
   - Maybe hardware sensors need manual tweaks
- [ ] Test mailing system
   - Setup `sasl_password`
   ```
   # write "smtp.larksuite.com username:password"
   postmap /etc/postfix/sasl_passwd
   rm /etc/postfix/sasl_passwd
   chmod 600 /etc/postfix/sasl_passwd.db
   ```
   - Test using `mail -s "Test Subject" user@example.com < /dev/null`
   - Test using `mail -s "Test Subject" root < /dev/null`
- [ ] Test smartd mail
      https://wiki.archlinux.org/title/S.M.A.R.T.
- [ ] Test ZED mail
      https://www.reddit.com/r/zfs/comments/fb8utq/how_to_test_zed_notification_emails/
- [ ] Check Grafana Loki log & alerts
- [ ] Check system firewall status
