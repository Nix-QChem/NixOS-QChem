subset: selfPkgs: superPkgs: self: super:

let
  callPackage = lib.callPackageWith (
    selfPkgs.pkgs //  # nixpkgs
    selfPkgs //       # overlay
    self //           # python
    overlay );

  lib = selfPkgs.pkgs.lib;

  overlay = {
    pychemps2 = callPackage ./chemps2/PyChemMPS2.nix { };
  } // lib.optionalAttrs super.isPy3k {
    pyscf = callPackage ./pyscf { };
  } // lib.optionalAttrs super.isPy27 {
    pyquante = callPackage ./pyquante { };
  };

in {
  "${subset}" = overlay; # subset for release
} // overlay             # Make sure non-python packages have access
