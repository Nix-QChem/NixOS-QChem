{ config ? {}, pin ? true } :


let

  pkgs = (import <nixpkgs>) {
    overlays = [ ((import ./default.nix) config) ];
    config.allowUnfree=true;
 };

in {
  inherit (pkgs)
    cp2k
    molcas
    nwchem
    molden;
} //
  (if builtins.hasAttr "srcurl" config then
  {
    inherit (pkgs)
      qdng
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

