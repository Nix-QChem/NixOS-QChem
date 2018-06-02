let
  pkgs = import <nixpkgs> {};

in {
  qchem = {
    inherit (pkgs)
      molden
      molcas
      nwchem
      gamess;
  };
}

