{ nixpkgs ? import <nixpkgs>
, config ? {}
}
let

  pkgs = nixpkgs { overlays = [ (import ./defaults.nix) config ]; }

in {
    inherit (pkgs)
      molden
      molcas
      nwchem
      gamess;
}

