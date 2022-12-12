subset: cfg: selfPkgs: superPkgs: self: super:

let
  callPackage = lib.callPackageWith (
    selfPkgs.pkgs //  # nixpkgs
    selfPkgs //       # overlay
    self //           # python
    overlay );

  inherit (selfPkgs.pkgs) lib;

  overlay = {

  } // lib.optionalAttrs super.isPy3k {
    adcc = callPackage ./pkgs/apps/adcc { };

    pyqdng = callPackage ./pkgs/apps/pyQDng { };

    gator = callPackage ./pkgs/apps/gator { };

    gau2grid = callPackage ./pkgs/apps/gau2grid { };

    meep = callPackage ./pkgs/apps/meep { };

    moltemplate = callPackage ./pkgs/apps/moltemplate { };

    openmm = callPackage ./pkgs/apps/openmm {
      enableCuda = cfg.useCuda;
    };

    optking = callPackage ./pkgs/lib/optking { };

    pdbfixer = callPackage ./pkgs/apps/pdbfixer { };

    polyply = callPackage ./pkgs/apps/polyply { };

    pylibefp = callPackage ./pkgs/lib/pylibefp { };

    psi4 = callPackage ./pkgs/apps/psi4 {
      libint = superPkgs.libintPsi4;
    };

    pychemps2 = callPackage ./pkgs/apps/chemps2/PyChemMPS2.nix { };

    pysisyphus = callPackage ./pkgs/apps/pysisyphus {
      gamess-us = selfPkgs.gamess-us.override {
        enableMpi = false;
      };
    };

    pyphspu = callPackage ./pkgs/lib/pyphspu { };

    rmsd = callPackage ./pkgs/lib/rmsd { };

    veloxchem = callPackage ./pkgs/apps/veloxchem { };

    vermouth = callPackage ./pkgs/apps/vermouth { };

    xtb-python = callPackage ./pkgs/lib/xtb-python { };
  } // lib.optionalAttrs super.isPy27 {
    pyquante = callPackage ./pkgs/apps/pyquante { };
  };

in {
  "${subset}" = overlay; # subset for release
} // overlay             # Make sure non-python packages have access
