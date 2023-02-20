{ pkgs ? import <nixpkgs> {}
, lib ? pkgs.lib
} :

let
  nixpkgs = import ./nixpkgs-pin.nix pkgs;

  pkgsNur = nixpkgs {
    overlays = [ (import ./default.nix) ];
    inherit (pkgs) config;
  };

in {
  overlays = {
    NixOS-QChem = import ./overlay.nix;
  };
} // pkgsNur.qchem


