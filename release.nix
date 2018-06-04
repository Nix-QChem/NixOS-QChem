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
    (import (fetchGit { url="https://github/NixOS/nixpkgs"; })) input;



in {
  inherit (pkgs)
    molcas
    nwchem
    molden;
} //
  (if builtins.hasAttr "srcurl" cfg then
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
  (if builtins.hasAttr "licMolpro" cfg then
  {
    inherit (pkgs)
      molpro;
  }
  else {}
  )

