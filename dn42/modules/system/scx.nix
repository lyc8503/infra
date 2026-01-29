{ config, lib, pkgs, ... }:

let
  scx_horoscope = pkgs.rustPlatform.buildRustPackage rec {
    pname = "scx_horoscope";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "zampierilucas";
      repo = "scx_horoscope";
      rev = "2ab63891358dbeeff18acee0415893a39fcc04d1";
      hash = "sha256-2Eeu7py0OQpho7U+g+liftbWrht0gK2JIHFKgaZzj1s=";
    };

    cargoHash = "sha256-smzOODMTSy1ISmUfIrC/7DffHB2+dcLx9kAtMAg7JTE=";

    nativeBuildInputs = with pkgs; [ clang pkg-config pkgs.llvmPackages.libclang ];
    buildInputs = with pkgs; [ elfutils zlib libseccomp ];

    hardeningDisable = [ "zerocallusedregs" ];

    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
  };
in
{
  options.services.scx_horoscope = {
    enable = lib.mkEnableOption "scx_horoscope scheduler";
  };

  config = lib.mkIf config.services.scx_horoscope.enable {
    environment.systemPackages = [ scx_horoscope ];

    # scx requires a kernel with CONFIG_SCHED_CLASS_EXT
    # We use linuxPackages_latest as it is most likely to have it.
    # boot.kernelPackages = pkgs.linuxPackages_latest;

    systemd.services.scx_horoscope = {
      description = "Astrological CPU Scheduler";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${scx_horoscope}/bin/scx_horoscope -w";
        Restart = "always";
        User = "root";
      };
    };
  };
}
