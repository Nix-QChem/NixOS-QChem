subset: selfPkgs: superPkgs: self: super:

let
  callPackage = superPkgs.lib.callPackageWith (
    selfPkgs.pkgs //  # nixpkgs
    selfPkgs //       # overlay
    self //           # python
    overlay );


  overlay = {
    pyscf = callPackage ./pyscf { };
    pyquante = callPackage ./pyquante { };
    pychemps2 = callPackage ./chemps2/PyChemMPS2.nix { };
  };

in {
  "${subset}" = overlay; # subset for release
} // overlay             # Make sure non-python packages have access
