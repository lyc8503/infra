{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }: {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ ];
        };
      };

      misc-vps = { name, nodes, pkgs, ... }: {
        deployment = {
          targetHost = "31.59.98.216";
          targetPort = 22;
          targetUser = "root";
        };

        imports = [
          ./configuration.nix
        ];
      };
    };
  };
}
