{
  # nixpkgs sources
    nixpkgs ? { outPath = <nixpkgs>; shortRev = "0000000"; }

  # Override config from ENV
  , config ? {}
  , NixOS-QChem ? { shortRev = "0000000"; }
} :


let
  # Custom package set
  pkgs = config: overlay: builtins.removeAttrs ((import nixpkgs) {
    overlays = [ overlay (import ./default.nix) ];
    config.allowUnfree = true;
    config.qchem-config = (import ./cfg.nix) config;
  }).qchem [ "pkgs" ];


in {
  qchem = pkgs (config // { optAVX = true;}) (self: super: {});
  qchem-mpich = pkgs (config // { optAVX = true;}) (self: super: { mpi = super.mpich; });
  qchem-noavx = pkgs (config // { optAVX = false;}) (self: super: {});
}
