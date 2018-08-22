{ config ? null, stable ? true } :


let

  qc-cfg = builtins.tryEval (import <qchem-config>);

  cfg = if config == null then
    if qc-cfg.success then
      qc-cfg.value
    else
     {}
  else
    config;

  input = {
    overlays = [ ((import ./default.nix) cfg) ];
    config.allowUnfree=true;
  };

  pkgs = if stable then
    (import <nixpkgs>) input
  else
    (import (fetchGit { url="https://github.com/NixOS/nixpkgs"; })) input;



in {
  openmpiPkgs = {
    inherit (pkgs.openmpiPkgs)
      bagel-mkl-scl
      bagel
      openmolcas
      nwchem;
  };

  mpichPkgs = {
    inherit (pkgs.mpichPkgs)
      bagel
      openmolcas
      nwchem;
  };

  mvapichPkgs = {
    inherit (pkgs.mvapichPkgs)
      bagel
      openmolcas
      nwchem;
  };

  scalapack=pkgs.openmpiPkgs.scalapackCompat-mkl;

  inherit (pkgs)
    bagel
    fftw
    molcas
    nwchem
    molden
    sharc;

   tests = {
     bagel = import ./tests/bagel-native.nix { pkgs=pkgs; bagel=pkgs.bagel; };
   };

} // (if builtins.hasAttr "srcurl" cfg then
  {
    inherit (pkgs)
      qdng
      gamess
      gamess-mkl
      mkl
      #impi
      molden;
  }
  else {}
  )
  // (if builtins.hasAttr "licMolpro" cfg then
  {
    inherit (pkgs)
      molpro;
  }
  else {}
  )

