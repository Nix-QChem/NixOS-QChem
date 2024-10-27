{
  description = "A flake for computational chemistry, based on NixOS-QChem";

  inputs = {
    qchem.url = "github:nix-qchem/nixos-qchem";
  };

  nixConfig = {
    extra-substituters = [ "https://nix-qchem.cachix.org" ];
    extra-trusted-public-keys = [ "nix-qchem.cachix.org-1:ZjRh1PosWRj7qf3eukj4IxjhyXx6ZwJbXvvFk3o3Eos=" ];
    allow-import-from-derivation = "true";
  };

  outputs = { self, qchem }:
    let
      # EDITME
      # Disables unfree packages by default to avoid non-building packages, that
      # use unfree ones as dependencies, e.g. Pysisyphus or SHARC.
      # Comment out lines to enable the respective package.
      filterUnfree = final: prev: {
        qchem = prev.qchem // {
          turbomole = null;
          cefine = null;
          cfour = null;
          gamess-us = null;
          gaussian = null;
          gaussview = null;
          mrcc = null;
          orca = null;
          vmd = null;
          mesa-qc = null;
          mcdth = null;
          nixGL = null;
        };
      };

      system = "x86_64-linux";
      pkgs = import qchem.inputs.nixpkgs {
        inherit system;
        overlays = [ qchem.overlays.default filterUnfree ];
        config = {
          allowUnfree = true;

          # EDITME
          qchem-config = {
            # Set to false if node does not support AVX2
            optAVX = true;

            # Set to an installation path of Gaussian outside the Nix
            # store if you have one. Should have a directory structure like this:
            #   "${optpath}/gaussian/g16/"
            #optpath = "/opt";

            # Set and uncomment if you have a MolPro license key.
            #licMolpro = "XXXX-XXXX-XXXX-XXXX";

            # Set and uncomment if you have a Q-Chem license key file.
            #licQChem = "/path/to/qchem.lic";

            # Uncomment if you have a server from which non-redistributable
            # software can be downloaded
            #srcurl = "http://myserver/nix-src/";
          };
        };
      };

      filterDrvs = pkgSet:
        pkgs.lib.filterAttrs (_: val: pkgs.lib.isDerivation val)
          pkgSet;
    in
    {
      # EDITME
      # Add packages to the default package as you wish
      packages."${system}" = (filterDrvs pkgs.qchem) // {
        default = pkgs.qchem.qlib.buildEnvMpi pkgs.symlinkJoin {
          name = "quantum-chemistry";
          paths = [
            # put a list of packages here. e.g.:
            #pkgs.qchem.orca
            #pkgs.qchem.psi4
            #pkgs.gnuplot
          ];
        };
      };
    };
}
