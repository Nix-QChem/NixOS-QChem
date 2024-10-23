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
              if (v ? meta.broken)
              then !v.meta.broken && isDerivation v
              else isDerivation v
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

      templates.default = {
        path = ./template;
        description = "NixOS-QChem template flake with reasonable defaults and editable configuration";
        welcomeText = ''
          Welcome to the NixOS-QChem template flake with optimised packages for computational chemistry!

          If you use this flake and/or packages from NixOS-QChem, please cite https://doi.org/10.1002/qua.26872 in your work!

          The flake aims for reasonable defaults but can be customised to your needs.
          Look for "EDITME" tokens in the flake.nix to find places where you can customise the flake,
          e.g. by adding or removing unfree packages, changing CPU architecture specific optimisations,
          or constructing a Python environment suiting your requirements.
        '';
      };
    };
}
