{
  description = "PhonerLite SIP softphone (Windows build) packaged for NixOS / Nix on Linux — runs on Wine with all the Wayland/KWin pitfalls pre-solved";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # PhonerLite is unfree (freeware); allow it inside the flake so
      # `nix run` / `nix build` work without the user's allowUnfree.
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages = forAllSystems (system: {
        default = self.packages.${system}.phonerlite;
        phonerlite = (pkgsFor system).callPackage ./packages/phonerlite.nix { };
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.phonerlite}/bin/phonerlite";
        };
      });

      overlays.default = final: prev: {
        phonerlite = final.callPackage ./packages/phonerlite.nix { };
      };

      # NixOS module: programs.phonerlite.enable = true;
      nixosModules.default = {
        imports = [ ./modules/nixos.nix ];
      };
    };
}
