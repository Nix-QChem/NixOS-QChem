{
  description = "A flake for computational chemistry, based on NixOS-QChem";

  inputs = {
    #qchem.url = "github:nix-qchem/nixos-qchem";
    qchem.url = "../";
  };

  nixConfig = {
    extra-substituters = [ "https://nix-qchem.cachix.org" ];

    allow-import-from-derivation = "true";
  };

  outputs = { self, qchem }:
    let
      # EDITME
      # Overlay to enable Gaussian support. Uncomment below in `pkgs` to enable.
      enableGaussian = final: prev: {
        qchem = prev.qchem // {
          gaussian = prev.callPackage "${qchem}/pkgs/apps/gaussian" {
            # Set a version
            version = "16c02";

            # Either set optpath
            optpath = "/opt";
            # or g16Root and g16Dir
            #g16Root = "/cluster/apps/gaussian/g16_c02";
            #g16Dir = "/cluster/apps/gaussian/g16_c02/g16";
          };
        };
      };

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
          gaussview = null;
          mrcc = null;
          orca = null;
          vmd = null;
          mesa-qc = null;
          mcdth = null;
          nixGL = null;
        };
      };

      # EDITME
      # Python environment for computational chemistry. Add or remove packages
      # as needed.
      pyCompEnv = pkgs.qchem.python3.withPackages (ps: with ps; [
        jupyterlab
        numpy
        scipy
        scikit-learn
        ase
        pyscf
        psi4
      ]);

      system = "x86_64-linux";

      pkgs = import qchem.inputs.nixpkgs {
        inherit system;

        # EDITME
        overlays = [
          qchem.overlays.default
          filterUnfree
          # enableGaussian # Uncomment to enable Gaussian support
        ];

        config = {
          allowUnfree = true;

          # EDITME
          qchem-config = {
            # Set to a GCC architecture to optimise packages for.
            # See https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html for options.
            optArch = "haswell";

            # Set to an installation path of Gaussian/MatLab outside the Nix
            # store if you have one. Should have a directory structure like this:
            #   "${optpath}/gaussian/g16/"
            #   "${optpath}/matlab-R2024/"
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
    in
    {
      # EDITME
      # A shell to obtain via `nix develop` or DirEnv, useful to run
      # programs interactively. Contains a Python environment for computational
      # chemistry. See above. Add/remove packages as needed.
      devShells."${system}".default = with pkgs; mkShell {
        buildInputs = [
          pyCompEnv
          pkgs.qchem.xtb
        ];
      };

      packages."${system}" = with pkgs.lib.attrsets;
        filterAttrs (_: val: isDerivation val)
          (pkgs.qchem // {
            inherit (pkgs) lammps lammps-mpi tachyon;
          });
    };
}
