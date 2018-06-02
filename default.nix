{ srcurl ? null  # base url for non-free packages
, licMolpro ?  null # string containing the license token
} :
self: super:


let
  # prefer 18.03
  #super = import (fetchTarball http://nixos.org/channels/nixos-18.03/nixexprs.tar.xz) {};

in with super; {

  ### Quantum Chem
  bagel = callPackage ./bagel {
    openblas= openblasCompat;
    scalapack= scalapackCompat.overrideAttrs ( super: { doCheck=false; } );
  };

  cp2k = callPackage ./cp2k { };

  molden = molden.overrideDerivation ( oldAttrs: {
    # Use a local version to overcome update dilema
    src = fetchurl {
      url = "${if srcurl == null
              then "ftp://ftp.cmbi.ru.nl/pub/molgraph/molden/"
              else srcurl}
              /molden5.7.tar.gz";
      sha256 = "12kir7xsd4r22vx8dyqin5diw8xx3fz4i3s849wjgap6ccmw1qqh";
    };
  });

  gamess = callPackage ./gamess { mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { mathlib=self.callPackage ./mkl { } ; useMkl = true; };

  ga = callPackage ./ga { };

  nwchem = callPackage ./nwchem { };

  molpro = callPackage ./molpro { srcurl=srcurl; token=licMolpro; };

  openmolcas = callPackage ./openmolcas {
    texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
    openblas = openblas;
  };

  molcas = self.openmolcas;

  qdng = callPackage ./qdng { srcurl=srcurl; };

  scalapackCompat = self.callPackage ./scalapack { openblas = openblasCompat; };

  scalapack = self.callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ### HPC libs and Tools

  ibsim = callPackage ./ibsim { };

  impi = callPackage ./impi { };

  libfabric = callPackage ./libfabric { };

  libint = callPackage ./libint { };

  libint-bagel = callPackage ./libint { cfg = [
    "--esuper.nable-eri=1"
    "--enable-eri3=1"
    "--enable-eri2=1"
    "--with-max-am=6"
    "--with-cartgauss-ordering=bagel"
    "--enable-contracted-ints"
  ];};

  mkl = callPackage ./mkl { };

  openmpi-ilp64 = callPackage ./openmpi { ILP64=true; };

  #openmpi = self openmpi { };

  openshmem = callPackage ./openshmem { };

  openshmem-smp = self.openshmem;

  openshmem-udp = callPackage ./openshmem { conduit="udp"; };

  openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

  openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

  sos = callPackage ./sos { };

  ucx = callPackage ./ucx { };
}


