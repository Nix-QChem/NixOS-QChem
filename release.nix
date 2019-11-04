{
  # If set to false the overlay will be used with
  # the latest nixpkgs from the master branch
  stable ? true

  # nixpkgs sources
, nixpkgs ? (import <nixpkgs>)
} :


let
  cfg = import ./cfg.nix;

  input = {
    overlays = [ (import ./default.nix) ];
    config.allowUnfree=true;
  };

  pkgs = if stable then
    (import <nixpkgs>) input
  else
    (import (fetchGit { url="https://github.com/NixOS/nixpkgs"; })) input;



in {
  openmpiPkgs = {
    inherit (pkgs.openmpiPkgs)
      cp2k
      bagel-mkl-scl
      bagel
      mctdh
      openmolcas
      openmolcas-mkl
      osu-benchmark
      nwchem;
  };

  mpichPkgs = {
    inherit (pkgs.mpichPkgs)
      hpl
      bagel
      openmolcas
      osu-benchmark
      nwchem;
  };

  mvapichPkgs = {
    inherit (pkgs.mvapichPkgs)
      bagel
      openmolcas
      osu-benchmark
      nwchem;
  };


  extra = {
    inherit (pkgs)
      libint
      libint1
      ibsim
      libxsmm
      sos
      openshmem
      openblas
      openblasCompat
      molcasUnstable
      osss-ucx
      pmix
      ucx;

  };

  scalapack=pkgs.openmpiPkgs.scalapack;

  inherit (pkgs)
    cp2k
    bagel
    ergoscf
    fftwOpt
    hpl
    hwloc-x11
    molcas
    nwchem
    molden
    sharc;

  #pyscf = pkgs.python3Packages.pyscf;

  # Packages depend on optimized libs
  deps = {
    python2 = {
      inherit (pkgs.python2Packages)
        numpy
        scipy;
    };

    python3 = {
      inherit (pkgs.python3Packages)
        numpy
        scipy;
    };
  };

   tests = {
     bagel = import ./tests/bagel-native.nix { pkgs=pkgs; bagel=pkgs.bagel; };
     bagelParallel = import ./tests/bagel-parallel.nix { pkgs=pkgs; bagel=pkgs.bagel; };
   };

} // (if cfg.srcurl != null then
  {
    inherit (pkgs)
      gaussview
      qdng
      mkl
      mesa-qc
      mctdh
      molden
      orca
      sharcV1
      vmd;
  }
  else {}
  )
  // (if cfg.licMolpro != null then
  {
    inherit (pkgs)
      molpro
      molpro12
      molpro15;
  }
  else {}
  ) // (if cfg.optpath != null  then
  {
    inherit (pkgs) gaussian;
  }
  else {}
  )

