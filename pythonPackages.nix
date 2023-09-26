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

    autodock-vina = callPackage ./pkgs/apps/autodock-vina/python.nix {
      inherit (finalPkgs) autodock-vina;
    };

    pycolt = callPackage ./pkgs/lib/pycolt { };

    cclib = callPackage ./pkgs/lib/cclib { };

    dftbplus = callPackage ./pkgs/apps/dftbplus { };

    pyqdng = callPackage ./pkgs/apps/pyQDng { };

    gator = callPackage ./pkgs/apps/gator { };

    gau2grid = callPackage ./pkgs/apps/gau2grid { };

    mdtraj = callPackage ./pkgs/lib/mdtraj { };

    mendeleev = callPackage ./pkgs/lib/mendeleev { };

    moltemplate = callPackage ./pkgs/apps/moltemplate { };

    optking = callPackage ./pkgs/lib/optking { };

    orbkit = callPackage ./pkgs/lib/orbkit { };

    theodore = callPackage ./pkgs/apps/theodore { };

    pdbfixer = callPackage ./pkgs/apps/pdbfixer { };

    polyply = callPackage ./pkgs/apps/polyply { };

    pylibefp = callPackage ./pkgs/lib/pylibefp { };

    psi4 = callPackage ./pkgs/apps/psi4 { };

    pyastronomy = callPackage ./pkgs/lib/pyastronomy { };

    pychemps2 = callPackage ./pkgs/apps/chemps2/PyChemMPS2.nix { };

    pymbar = callPackage ./pkgs/lib/pymbar { };

    pysisyphus = callPackage ./pkgs/apps/pysisyphus {
      gamess-us = finalPkgs.gamess-us.override {
        enableMpi = false;
      };
    };

    pyphspu = callPackage ./pkgs/lib/pyphspu { };

    svgutils = callPackage ./pkgs/lib/svgutils { };

    veloxchem = callPackage ./pkgs/apps/veloxchem { };

    vermouth = callPackage ./pkgs/apps/vermouth { };

    vmd-python = callPackage ./pkgs/apps/vmd-python {
      inherit cfg;
    };

    xtb-python = callPackage ./pkgs/lib/xtb-python { };
  } // lib.optionalAttrs prev.isPy27 {
    pyquante = callPackage ./pkgs/apps/pyquante { };
  };

in {
  "${subset}" = overlay; # subset for release
} // overlay             # Make sure non-python packages have access
