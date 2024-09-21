{
  disko = {
    # 不要让 Disko 直接管理 NixOS 的 fileSystems.* 配置。
    # 原因是 Disko 默认通过 GPT 分区表的分区名挂载分区，但分区名很容易被 fdisk 等工具覆盖掉。
    # 导致一旦新配置部署失败，磁盘镜像自带的旧配置也无法正常启动。
    enableConfig = false;

    devices = {
      # 定义一个磁盘
      disk.main = {
        # 要生成的磁盘镜像的大小，2GB 足够我使用，可以按需调整
        imageSize = "2G";
        # 磁盘路径。Disko 生成磁盘镜像时，实际上是启动一个 QEMU 虚拟机走一遍安装流程。
        # 因此无论你的 VPS 上的硬盘识别成 sda 还是 vda，这里都以 Disko 的虚拟机为准，指定 vda。
        device = "/dev/vda";
        type = "disk";
        # 定义这块磁盘上的分区表
        content = {
          # 使用 GPT 类型分区表。Disko 对 MBR 格式分区的支持似乎有点问题。
          type = "gpt";
          # 分区列表
          partitions = {
            # GPT 分区表不存在 MBR 格式分区表预留给 MBR 主启动记录的空间，因此这里需要预留
            # 硬盘开头的 1MB 空间给 MBR 主启动记录，以便后续 Grub 启动器安装到这块空间。
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
              # 优先级设置为最高，保证这块空间在硬盘开头
              priority = 0;
            };

            # ESP 分区，或者说是 boot 分区。这套配置理论上同时支持 EFI 模式和 BIOS 模式启动的 VPS。
            ESP = {
              name = "ESP";
              # 根据我个人的需求预留 512MB 空间。如果你的 boot 分区占用更大/更小，可以按需调整。
              size = "512M";
              type = "EF00";
              # 优先级设置成第二高，保证在剩余空间的前面
              priority = 1;
              # 格式化成 FAT32 格式
              content = {
                type = "filesystem";
                format = "vfat";
                # 用作 Boot 分区，Disko 生成磁盘镜像时根据此处配置挂载分区，需要和 fileSystems.* 一致
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077"];
              };
            };

            # 存放 NixOS 系统的分区，使用剩下的所有空间。
            zfs = {
              size = "100%";
              # 格式化成 zfs，可以按需修改
              content = {
                type = "zfs";
                pool = "pool";
              };
            };
          };
        };
      };

      zpool = {
        pool = {
          type = "zpool";

          datasets = {
            nix = {
              type = "zfs_fs";
              mountpoint = "/nix";
              mountOptions = ["zfsutil"];
            };

            persist = {
              type = "zfs_fs";
              mountpoint = "/persist";
              mountOptions = ["zfsutil"];
            };
          };
        };
      };

      # 由于我开了 Impermanence，需要声明一下根分区是 tmpfs，以便 Disko 生成磁盘镜像时挂载分区
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = ["defaults" "size=2G" "mode=755"];
      };
    };
  };
}