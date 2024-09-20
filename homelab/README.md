# HomeLab Proxmox VE ansible playbook

## System installation (manual steps)

Tested on: PVE 8.2-2 graphical installer

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
zpool import -f -NR rpool

zfs destroy rpool/var-lib-vz
zfs destroy rpool/data

zfs snapshot -r rpool/ROOT@copy
zfs send -R rpool/ROOT@copy | zfs recv rpool/copyroot
zfs destroy -r rpool/ROOT

zfs create -o encryption=on -o keyformat=passphrase rpool/ROOT
zfs create -o encryption=on -o keyformat=passphrase rpool/data
zfs create -o encryption=on -o keyformat=passphrase rpool/pve

zfs send -R rpool/copyroot/pve-1@copy | zfs receive -o encryption=on rpool/ROOT/pve-1
zfs destroy -r rpool/copyroot
zfs set mountpoint=/ rpool/ROOT/pve-1

zpool export rpool

# reboot
```

After reboot, you should be prompted to enter your password set just now.

Login into dashboard, remove `local-zfs` in `Datacenter-Storage`, create a new `ZFS` storage with `rpool/pve`

**TODO: remote unlock and auto unlock**

---

## Ansible

Now you can deploy the playbook on the fresh-installed PVE system:

```

```

## Deployment checklist

1. Test Netdata dashboard
   - Maybe hardware sensors need manual tweaks
2. Test mailing system
   - Setup `sasl_password`
     write `smtp.larksuite.com username:password` and then `postmap /etc/postfix/sasl_passwd`, `rm /etc/postfix/sasl_passwd`, `chmod 600 /etc/postfix/sasl_passwd.db`
   - `mail -s "Test Subject" user@example.com < /dev/null`