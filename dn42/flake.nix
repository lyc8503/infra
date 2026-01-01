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
      do-syd1 = import ./hosts/do-syd1/default.nix;
      do-tor1 = import ./hosts/do-tor1/default.nix;
      do-lon1 = import ./hosts/do-lon1/default.nix;
      neo-misc = import ./hosts/neo-misc/default.nix;
      az-sg1 = import ./hosts/az-sg1/default.nix;
      az-hk1-arm = import ./hosts/az-hk1-arm/default.nix;
    };
  };
}
