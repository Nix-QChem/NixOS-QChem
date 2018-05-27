{ srcurl ? null  # base url for non-free packages
, licMolpro ?  null # string containing the license token
} : self: super:

let
  # prefer 18.03
  pkgs = import (fetchTarball http://nixos.org/channels/nixos-18.03/nixexprs.tar.xz) {};

  callPackage = pkgs.lib.callPackageWith (pkgs // pkgs-qc);

  pkgs-qc = with pkgs; rec {

    ### Quantum Chem
    bagel = callPackage ./bagel {
      openblas=openblasCompat;
      scalapack=scalapackCompat.overrideAttrs ( super: { doCheck=false; } ); };

    cp2k = callPackage ./cp2k { };

    molden = super.molden;

    gamess = callPackage ./gamess { mathlib=atlas; };

    gamess-mkl = callPackage ./gamess { mathlib=callPackage ./mkl { } ; useMkl = true; };

    ga = callPackage ./ga { };

    libxc = super.libxc;

    nwchem = callPackage ./nwchem { };

    molpro = callPackage ./molpro { srcurl=srcurl; token=licMolpro; };

    octopus = super.octopus;

    openmolcas = callPackage ./openmolcas {
#texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      texLive=texlive.combined.scheme-basic;
      openblas=openblas;
    };

    qdng = callPackage ./qdng { srcurl=srcurl; };

    scalapackCompat = callPackage ./scalapack { openblas=openblasCompat; };

    scalapack = callPackage ./scalapack { mpi=openmpi-ilp64; };

    ### HPC libs and Tools

    ibsim = callPackage ./ibsim { };

    impi = callPackage ./impi { };

    infiniband-diags = callPackage ./infiniband-diags { };

    libfabric = callPackage ./libfabric { };

    libint = callPackage ./libint { };

    libint-bagel = callPackage ./libint { cfg = [
      "--enable-eri=1"
      "--enable-eri3=1"
      "--enable-eri2=1"
      "--with-max-am=6"
      "--with-cartgauss-ordering=bagel"
      "--enable-contracted-ints"
    ];};

    mkl = callPackage ./mkl { };

    openmpi-ilp64 = callPackage ./openmpi { ILP64=true; };

    openmpi = callPackage ./openmpi { };

    openshmem = callPackage ./openshmem { };

    openshmem-smp = openshmem;

    openshmem-udp = callPackage ./openshmem { conduit="udp"; };

    openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

    openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

    opensm =  callPackage ./opensm { };

    slurmSpankX11 = pkgs.slurmSpankX11; # make X11 work in srun sessions

    sos = callPackage ./sos { };

    ucx = callPackage ./ucx { };
  };

in pkgs-qc

