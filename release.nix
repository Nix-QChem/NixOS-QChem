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
      cp2k
      bagel-mkl-scl
      bagel
      hpl
      openmolcas
      openmolcas-mkl
      osu-benchmark
      nwchem;
  };

  mpichPkgs = {
    inherit (pkgs.mpichPkgs)
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

  # upstream packages
  # that need recompiling
  upstream = {
    inherit (pkgs)
      octave;

    python27scipy = pkgs.python27Packages.scipy;
    python37scipy = pkgs.python37Packages.scipy;
    python37h5py = pkgs.python37Packages.h5py;

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
    molcas
    nwchem
    molden
    sharcV1
    sharc
    sharc21;

  pyscf = pkgs.python3Packages.pyscf;

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

} // (if builtins.hasAttr "srcurl" cfg then
  {
    inherit (pkgs)
      gaussview
      qdng
      mkl
      mesa-qc
      mctdh
      molden
      orca;
  }
  else {}
  )
  // (if builtins.hasAttr "licMolpro" cfg then
  {
    inherit (pkgs)
      molpro
      molpro12
      molpro15
      molpro18;
  }
  else {}
  ) // (if builtins.hasAttr "optpath" cfg then
  {
    inherit (pkgs) gaussian;
  }
  else {}
  )

