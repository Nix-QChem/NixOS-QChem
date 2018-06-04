{ srcurl ? null  # base url for non-free packages
, licMolpro ?  null # string containing the license token
, optAVX ? true # turn of AVX optimizations
} :
self: super:


let
  lF = { sha256, srcfile, website ? "" } :
  if srcurl != null then
    super.fetchurl {
      url = srcurl + "/" + srcfile;
      sha256 = sha256;
    }
  else
   super.requireFile {
      url = website;
      name = srcfile;
      inherit sha256;
    };


in with super; {

  ### Quantum Chem
  bagel = callPackage ./bagel {
    openblas= openblasCompat;
    scalapack= self.scalapackCompat.overrideAttrs ( super_: { doCheck=false; } );
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

  gamess = callPackage ./gamess { localFile=lF; mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { localFile=lF; mathlib=self.mkl; useMkl = true; };

  ga = callPackage ./ga { };

  nwchem = callPackage ./nwchem { };

  molpro = callPackage ./molpro { localFile=lF; token=licMolpro; };

  openmolcas = callPackage ./openmolcas {
    texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
    openblas = openblas;
  };

  molcas = self.openmolcas;

  qdng = callPackage ./qdng { localFile=lF; };

  scalapackCompat =callPackage ./scalapack { openblas = openblasCompat; };

#  scalapack = callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ### HPC libs and Tools

  fftw = if optAVX then
    fftw.overrideDerivation ( oldAttrs: {
    configureFlags = oldAttrs.configureFlags
      ++ [ "--enable-avx" "--enable-avx2" "--enable-generic-simd256" ];
  })
  else
    super.fftw;

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

  mkl = callPackage ./mkl { localFile=lF; };

#  openmpi-ilp64 = callPackage ./openmpi { ILP64=true; };

  #openmpi = self openmpi { };

  openshmem = callPackage ./openshmem { };

#  openshmem-smp = self.openshmem;

  openshmem-udp = callPackage ./openshmem { conduit="udp"; };

  openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

  openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

  sos = callPackage ./sos { };

  ucx = callPackage ./ucx { };
}


