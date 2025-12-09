{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    colmena.url = "github:zhaofengli/colmena";
  };
  outputs = { nixpkgs, colmena, ... }: {
    colmenaHive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [];
        };
      };

      do-sgp1 = import ./hosts/do-sgp1/default.nix;
      do-ams1 = import ./hosts/do-ams1/default.nix;
      do-sfo1 = import ./hosts/do-sfo1/default.nix;
    };
  };
}
