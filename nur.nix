{ pkgs ? import <nixpkgs> {} } :
let
  # Pin nixpkgs to unstable version that contains the
  # mpi attribute mod. Remove it later.
  rev = "2f34b4b883932f0ee2c1787e704f3915786e8cca";
  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";

  # Only expose top level derivations
  filterDerivations = pkgSet: with pkgs.lib; filterAttrs (name: value: isDerivation value) pkgSet;

  # create the package set
  pkgsUnstable = (import nixpkgs) {
    overlays = [ (import ./default.nix) ];

    config = {
      allowUnfree = true;
      qchem-config = {
        allowEnv = true;
        optAVX = true;
      };
    };
  };

in {
  overlays = {
    NixOS-QChem = import ./default.nix;
  };
} // filterDerivations pkgsUnstable.qchem


