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
      boost = finalPkgs.pkgs.boost182;
    };

    biopython = prev.biopython.overrideAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    });

    dftbplus = callPackage ./pkgs/by-name/dftbplus/pythonapi.nix {
      inherit (finalPkgs) dftbplus;
    };
    dptools = callPackage ./pkgs/by-name/dftbplus/dptools.nix {
      inherit (finalPkgs) dftbplus;
    };

    psi4 = callPackage ./pkgs/python-by-name/psi4/package.nix { inherit (finalPkgs) libxc; };

    pychemps2 = callPackage ./pkgs/apps/chemps2/PyChemMPS2.nix { };

    pysisyphus = callPackage ./pkgs/python-by-name/pysisyphus/package.nix {
      gamess-us = finalPkgs.gamess-us.override {
        enableMpi = false;
      };
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
