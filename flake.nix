{
  description = "NixOS-QChem flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  nixConfig = {
    extra-substituters = [ "https://nix-qchem.cachix.org" ];
    extra-trusted-public-keys = [ "nix-qchem.cachix.org-1:ZjRh1PosWRj7qf3eukj4IxjhyXx6ZwJbXvvFk3o3Eos=" ];

    allow-import-from-derivation = "true";
  };

  outputs = { self, nixpkgs, ... }:
    let
      qchemOvl = import ./overlay.nix;

      system = "x86_64-linux";

      pkgs = (import nixpkgs) {
        inherit system;
        overlays = [
          qchemOvl
          (final: prev: {
            qchem = prev.qchem // {
              turbomole = null;
              cefine = null;
              cfour = null;
              gamess-us = null;
              gaussview = null;
              mrcc = null;
              orca = null;
              vmd = null;
              mesa-qc = null;
              mcdth = null;
              nixGL = null;
            };
          })
        ];
        config.allowUnfree = true;
        config.qchem-config = (import ./cfg.nix) {
          allowEnv = false;
          optAVX = true;
        };
      };

      inherit (pkgs) lib;

      # Cleaned package set, i.e. packages that
      #  * build correctly
      #  * are not insecure (thus, remove all python2 packages)
      pkgsClean = with lib;
        let
          buildingPkgs = filterAttrs
            (k: v:
              if (builtins.tryEval v).success
              then
                if (v ? meta.broken)
                then !v.meta.broken && isDerivation v
                else isDerivation v
              else false
            )
            pkgs.qchem;
          securePackages = builtins.removeAttrs buildingPkgs [ "python2" ];
        in
        securePackages;

    in
    {
      packages."${system}" = pkgsClean;

      hydraJobs."${system}" = pkgsClean;

      checks."${system}" = with lib; filterAttrs (n: isDerivation) pkgs.qchem.tests;

      formatter."${system}" = pkgs.nixpkgs-fmt;

      devShells."${system}".default = with pkgs; mkShell {
        buildInputs = [
          self.formatter."${system}"
          statix
        ];
      };

      overlays = {
        qchem = qchemOvl;
        qchem' = import ./default.nix;
        pythonQchem = import ./pythonPackages.nix pkgs.config.qchem-config.prefix pkgs.config.qchem-config pkgs nixpkgs;
        default = self.overlays.qchem;
      };
    };
}
