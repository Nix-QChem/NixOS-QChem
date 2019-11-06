self: super:

let
  callPackage = super.callPackage;

in {
  pyscf = callPackage ./pyscf { };
  pyquante = callPackage ./pyquante { };
  pychemps2 = callPackage ./chemps2/PyCheMPS2.nix { };
}
