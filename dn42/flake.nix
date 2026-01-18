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


      do-sfo1 = import ./hosts/do-sfo1/default.nix;
      neo-misc = import ./hosts/neo-misc/default.nix;
      az-sg1 = import ./hosts/az-sg1/default.nix;
      az-hk1-arm = import ./hosts/az-hk1-arm/default.nix;
      scw-ams1 = import ./hosts/scw-ams1/default.nix;
      gcp-chs1 = import ./hosts/gcp-chs1/default.nix;
    };
  };
}
