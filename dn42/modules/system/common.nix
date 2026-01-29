{ config, pkgs, lib, ... }:

{
  imports = [ ./scx.nix ../services/xjbcast.nix ];

  boot.kernelModules = [ "tcp_bbr" ];

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  services.scx_horoscope.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    wget
    curl
    htop
    btop
    screen
    tmux
    fzf
    ripgrep
    bat
    lsd
    jq
    gawk
    ncdu
    neofetch
    dnsutils
    mtr
    iperf3
    tcpdump
    pwru
    python3
    termshark
    iptables
    hping
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" "systemd" "extract" ];
      theme = "robbyrussell";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
    };
  };

  users.defaultUserShell = pkgs.zsh;

  environment.shellAliases = {
    ll = "lsd -l";
    ls = "lsd";
    cat = "bat";
    vi = "nvim";
    vim = "nvim";
  };

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWoJPZpwxXDJLa0RpNkZTZHnt6bnT4FTrXBCG/EZdQD82x8qald0p5tWscdJmDwxkwcZVcdYKUI0FqLeJrvzWBg4wQ9Ldb70T754brmxJC5wnAXS+WL50nACE+3OG7fKWpetVXNyXi3DaLEhz0PI2xqxedxVyflhHMOtl4yGa7k9DBNR9HnCbTpxyqA82tTjfIzl6qg6COwrv7oZcMlQOs24z/64nxVvwsHPeIV/9m6GoZcBUdRnBjv91mLCWM9hmYRu38dTWpmzun4x9/TV8/J4jBknClsC/M9V+kuebTEW8H0xv7Iw1DJ/NCtj1/XEeAbtyVy4jdRkzVhN4Kwt/JiIZAlvDRvbLjgkmnpYmM9hFJpNEL/zerxZokUugQIB/XmS5dD92eV5G9n3KLIrfZ0jY6Suz2AmzqSBq9RX3xr4KJHspOCQdPVAXYtKwXKVPuT3Ksqux8k6xC1mNuIVbctkRLwPlcycX4qdKG0qD/4wur0a1JjZP7RgVHhdsU3LM= ubuntu"
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  networking.firewall.enable = false;
  networking.firewall.checkReversePath = false;
  zramSwap.enable = true;

  # Disable NetworkManager-wait-online to prevent deployment timeouts
  # DN42 nodes have many WireGuard interfaces that may not be immediately online
  systemd.services.NetworkManager-wait-online.enable = false;
}