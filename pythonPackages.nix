subset: cfg: finalPkgs: prevPkgs: final: prev:

let
  callPackage = lib.callPackageWith (
    finalPkgs.pkgs //  # nixpkgs
    finalPkgs //       # overlay
    final //           # python
    overlay );

  inherit (finalPkgs.pkgs) lib;

  overlay = {

  } // lib.optionalAttrs prev.isPy3k {
    adcc = callPackage ./pkgs/apps/adcc { };

    dftbplus = callPackage ./pkgs/apps/dftbplus {
      inherit (finalPkgs) tblite;
    };

    pyqdng = callPackage ./pkgs/apps/pyQDng { };

    gator = callPackage ./pkgs/apps/gator { };

    gau2grid = callPackage ./pkgs/apps/gau2grid { };

    moltemplate = callPackage ./pkgs/apps/moltemplate { };

    optking = callPackage ./pkgs/lib/optking { };

    pdbfixer = callPackage ./pkgs/apps/pdbfixer { };

    polyply = callPackage ./pkgs/apps/polyply { };

    pylibefp = callPackage ./pkgs/lib/pylibefp { };

    psi4 = callPackage ./pkgs/apps/psi4 {
      libint = prevPkgs.libintPsi4;
    };

    pychemps2 = callPackage ./pkgs/apps/chemps2/PyChemMPS2.nix { };

    pysisyphus = callPackage ./pkgs/apps/pysisyphus {
      gamess-us = finalPkgs.gamess-us.override {
        enableMpi = false;
      };
    };

    pyphspu = callPackage ./pkgs/lib/pyphspu { };

    veloxchem = callPackage ./pkgs/apps/veloxchem { };

    vermouth = callPackage ./pkgs/apps/vermouth { };

    xtb-python = callPackage ./pkgs/lib/xtb-python { };
  } // lib.optionalAttrs prev.isPy27 {
    pyquante = callPackage ./pkgs/apps/pyquante { };
  };

in {
  "${subset}" = overlay; # subset for release
} // overlay             # Make sure non-python packages have access
