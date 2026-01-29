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


      do-sfo1 = import ./hosts/do-sfo1/configuration.nix;
      neo-misc = import ./hosts/neo-misc/configuration.nix;
      az-sg1 = import ./hosts/az-sg1/configuration.nix;
      az-hk1-arm = import ./hosts/az-hk1-arm/configuration.nix;
      scw-ams1 = import ./hosts/scw-ams1/configuration.nix;
      gcp-chs1 = import ./hosts/gcp-chs1/configuration.nix;
    };
  };
}
