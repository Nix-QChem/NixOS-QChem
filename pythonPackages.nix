{ stdenv, python } :

let
  packageOverrides = self: super: {
    pyscf = self.python.pkgs.callPackage ./pyscf { };
  };

in python.override {inherit packageOverrides;}
