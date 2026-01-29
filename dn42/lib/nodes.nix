{
  asn = 4242420167;
  domain = "dn42.42420167.xyz";

  anycast = {
    ipv4 = "172.23.41.81";
    ipv6 = "fd32:3940:2738::1";
  };

  ipv4Range = "172.23.41.64/26";
  ipv6Range = "fd32:3940:2738::/48";

  nodes = {
    neo-misc = {
      id = 1;
      hostname = "neo-misc";
      logicalName = "sgp1";

      publicIpv4 = "188.239.22.57";
      publicIpv6 = "2a01:4f8:c012:a4d7::1";

      dn42 = {
        ipv4 = {
          addresses = [ "172.20.42.224" "172.23.41.81" ];
          dnetAddress = "172.20.42.240";
          networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
        };
        ipv6 = {
          addresses = [ "fd00:1100:8503::1" "fd32:3940:2738::1" ];
          networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
        };
      };

      dnet = {
        address = "172.20.42.240";
        netmask = "255.255.255.255";
        cidr = "172.20.42.240/32";
      };

      services = {
        xjbcast = { enable = false; };
      };

      deployment = {
        targetHost = "188.239.22.57";
        targetUser = "root";
        tags = [ "neo" "vps" ];
      };
    };

    scw-ams1 = {
      id = 2;
      hostname = "scw-ams1";
      logicalName = "ams1";

      publicIpv6 = "2001:bc8:1640:4f16:f5bf:e8bf:fd1d:e65a";

      dn42 = {
        ipv4 = {
          addresses = [ "172.20.42.225" "172.23.41.81" ];
          dnetAddress = "172.20.42.241";
          networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
        };
        ipv6 = {
          addresses = [ "fd00:1100:8503::2" "fd32:3940:2738::1" ];
          networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
        };
      };

      dnet = {
        address = "172.20.42.241";
        netmask = "255.255.255.255";
        cidr = "172.20.42.241/32";
      };

      services = {
        xjbcast = { enable = true; };
        xray = { traffic = 500; };
        hysteria = { traffic = 500; };
        warp = {
          enable = true;
          allowedIPs = [ "1.1.1.1/32" ];
        };
      };

      deployment = {
        targetHost = "2001:bc8:1640:4f16:f5bf:e8bf:fd1d:e65a";
        targetUser = "root";
        tags = [ "scaleway" "vps" ];
      };
    };

    do-sfo1 = {
      id = 3;
      hostname = "do-sfo1";
      logicalName = "sfo1";

      publicIpv4 = "64.227.99.106";
      publicIpv6 = "2604:a880:4:1d0:0:1:4500:1000";

      dn42 = {
        ipv4 = {
          addresses = [ "172.20.42.226" "172.23.41.81" ];
          dnetAddress = "172.20.42.242";
          networks = [ "172.20.42.224/27" "172.23.41.80/28" ];
        };
        ipv6 = {
          addresses = [ "fd00:1100:8503::3" "fd32:3940:2738::1" ];
          networks = [ "fd00:1100:8503::/48" "fd32:3940:2738::/48" ];
        };
      };

      dnet = {
        address = "172.20.42.242";
        netmask = "255.255.255.255";
        cidr = "172.20.42.242/32";
      };

      services = {
        xjbcast = { enable = true; };
        xray = { traffic = 300; };
        hysteria = { traffic = 300; };
        tor-relay = {
          enable = true;
          anchorIPv4 = "10.48.0.5";
          ipv4Gateway = "10.48.0.1";
          monthlyLimitGB = 200;
        };
        tcpdump = { enable = true; };
      };

      deployment = {
        targetHost = "64.227.99.106";
        targetUser = "root";
        tags = [ "digitalocean" "vps" ];
      };
    };

    gcp-chs1 = {
      id = 4;
      hostname = "gcp-chs1";
      logicalName = "chs1";

      publicIpv4 = "35.211.99.153";

      dn42 = {
        ipv4 = {
          addresses = [ "172.20.42.227" ];
          dnetAddress = "172.20.42.243";
          networks = [ "172.20.42.224/27" ];
        };
        ipv6 = {
          addresses = [ "fd00:1100:8503::4" ];
          networks = [ "fd00:1100:8503::/48" ];
        };
      };

      dnet = {
        address = "172.20.42.243";
        netmask = "255.255.255.255";
        cidr = "172.20.42.243/32";
      };

      services = {
        warp = {
          enable = true;
          address = [ "2606:4700:110:8eb4:6b54:7ffe:4c25:35fa/128" ];
          allowedIPs = [ "::/0" ];
        };
        traffic-limit = {
          enable = true;
          limitGB = 180;
          dryRun = true;
        };
      };

      deployment = {
        targetHost = "35.211.99.153";
        targetUser = "root";
        tags = [ "gcp" "vps" ];
      };
    };

    az-hk1-arm = {
      id = 5;
      hostname = "az-hk1-arm";
      logicalName = "hkg1";

      publicIpv4 = "20.2.153.221";

      dn42 = {
        ipv4 = {
          addresses = [ "172.20.42.228" ];
          dnetAddress = "172.20.42.244";
          networks = [ "172.20.42.224/27" ];
        };
        ipv6 = {
          addresses = [ "fd00:1100:8503::5" ];
          networks = [ "fd00:1100:8503::/48" ];
        };
      };

      dnet = {
        address = "172.20.42.244";
        netmask = "255.255.255.255";
        cidr = "172.20.42.244/32";
      };

      services = {
        xray = { traffic = 200; };
        hysteria = { traffic = 200; };
        scx_horoscope = { enable = false; };
      };

      deployment = {
        targetHost = "20.2.153.221";
        targetUser = "root";
        tags = [ "azure" "vps" "arm" ];
      };
    };

    az-sg1 = {
      id = 6;
      hostname = "az-sg1";
      logicalName = "sgp2";

      publicIpv4 = "13.76.30.153";

      dn42 = {
        ipv4 = {
          addresses = [ "172.20.42.229" ];
          dnetAddress = "172.20.42.245";
          networks = [ "172.20.42.224/27" ];
        };
        ipv6 = {
          addresses = [ "fd00:1100:8503::6" ];
          networks = [ "fd00:1100:8503::/48" ];
        };
      };

      dnet = {
        address = "172.20.42.245";
        netmask = "255.255.255.255";
        cidr = "172.20.42.245/32";
      };

      services = {
        xray = { traffic = null; };
        hysteria = { traffic = null; };
        tcpdump = { enable = true; };
      };

      deployment = {
        targetHost = "13.76.30.153";
        targetUser = "root";
        tags = [ "azure" "vps" ];
      };
    };
  };
}
