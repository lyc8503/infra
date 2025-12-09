{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    htop
    screen
  ];

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

  networking.firewall.enable = true;
  zramSwap.enable = true;
}