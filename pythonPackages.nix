subset: cfg: finalPkgs: prevPkgs: final: prev:

let
  callPackage = lib.callPackageWith (
    finalPkgs.pkgs //  # nixpkgs
    finalPkgs //       # overlay
    final //           # python
    overlay );

  inherit (finalPkgs.pkgs) lib;
  qlib = import ./lib.nix { inherit lib; };

  overlay = {

  } // lib.optionalAttrs prev.isPy3k (qlib.pkgs-by-name callPackage ./pkgs/python-by-name)
    // lib.optionalAttrs prev.isPy3k {

    autodock-vina = callPackage ./pkgs/apps/autodock-vina/python.nix {
      inherit (finalPkgs) autodock-vina;
    };

    biopython = prev.biopython.overrideAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    });

    pychemps2 = callPackage ./pkgs/apps/chemps2/PyChemMPS2.nix { };

    pysisyphus = callPackage ./pkgs/python-by-name/pysisyphus/package.nix {
      gamess-us = finalPkgs.gamess-us.override {
        enableMpi = false;
      };
      enableOrca = finalPkgs.orca != null;
      enableTurbomole = finalPkgs.turbomole != null;
      enableGaussian = finalPkgs.gaussian != null;
      enableCfour = finalPkgs.cfour != null;
      enableMolpro = finalPkgs.molpro != null;
      enableGamess = finalPkgs.gamess-us != null;
    };

    qmcpack = callPackage ./pkgs/python-by-name/qmcpack/package.nix {
      inherit (finalPkgs.pkgs) libxml2;
    };

    vmd-python = callPackage ./pkgs/python-by-name/vmd-python/package.nix {
      inherit cfg;
      inherit (finalPkgs.pkgs) mesa;
    };
  };

in {
  "${subset}" = overlay; # subset for release
} // overlay             # Make sure non-python packages have access
