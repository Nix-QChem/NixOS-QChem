{
  # nixpkgs sources
    nixpkgs ? <nixpkgs>

  # Override config from ENV
  , config ? {}
} :


let
  # options for nixpkgs
  input = {
    overlays = [ (import ./default.nix) ];
    config.allowUnfree = true;
    config.qchem-config = (import ./cfg.nix) config;
  };

  # import package set
  pkgs = (import nixpkgs) input;

  cfg = pkgs.config.qchem-config;

jobs = rec {
  openmpiPkgs = {
    inherit (pkgs.openmpiPkgs)
      cp2k
      hpl
      bagel
      mctdh
      osu-benchmark
      nwchem;
  };

  extra = {
    inherit (pkgs)
      libint2
      libint1
      mkl
      quantum-espresso
      quantum-espresso-mpi
      siesta-mpi
      siesta
      octopus
      gromacsDoubleMpi
      gromacsDouble
      libxsmm
      openblas
      openblasCompat
      spglib;

  };

  scalapack = pkgs.openmpiPkgs.scalapack;

  inherit (pkgs)
    chemps2
    cp2k
    bagel
    bagel-serial
    ergoscf
    fftwOpt
    hwloc-x11
    hpcg
    molcas
    molden
    molcasUnstable
    mt-dgemm
    nwchem
    octave
    sharcV1
    sharc
    sharc21
    stream-benchmark;

  #pyscf = pkgs.python3Packages.pyscf;
  pychemps2 = pkgs.python3Packages.pychemps2;
  pyquante = pkgs.python2Packages.pyquante;

  # Packages depending on optimized libs
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
    inherit (pkgs.qc-tests)
      cp2k
      nwchem
      molcas
      molpro
      mesa-qc
      qdng;
  };

  tested = with pkgs; releaseTools.aggregate {
    name = "tests";
    constituents = [
      tests.cp2k
      tests.nwchem
      tests.molcas
      tests.molpro
    ] ++ lib.optionals (cfg.srcurl != null) [
      tests.mesa-qc
      tests.qdng
    ];
  };

} // (if cfg.srcurl != null then
  {
    inherit (pkgs)
      gaussview
      qdng
      mesa-qc
      mctdh
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
      molpro15
      molpro18;
  }
  else {}
  ) // (if cfg.optpath != null  then
  {
    inherit (pkgs) gaussian;
  }
  else {}
  );

in jobs


