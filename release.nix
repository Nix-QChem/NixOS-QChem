{ config ? {}, stable ? true } :


let
  input = {
    overlays = [ ((import ./default.nix) config) ];
    config.allowUnfree=true;
  };

#  if stable then
    pkgs = (import <nixpkgs>) input;
#  else
#    (pkgs = (import (fetchGit { url="https://github/NixOS/nixpkgs"; })) input)


in {
  inherit (pkgs)
    molcas
    nwchem
    molden;
} //
  (if builtins.hasAttr "srcurl" config then
  {
    inherit (pkgs)
      qdng
      gamess
      gamess-mkl
      mkl
      molden;
  }
  else {}
  )
  //
  (if builtins.hasAttr "licMolpro" config then
  {
    inherit (pkgs)
      molpro;
  }
  else {}
  )

