{ srcurl ? null  # base url for non-free packages
, licMolpro ?  null # string containing the license token
, optAVX ? true # turn of AVX optimizations
} :
self: super:


let
  # build a package with specfific MPI implementation
  withMpi = pkg : mpi :
    super.appendToName mpi.name (pkg.override { mpi = mpi; });

  # Build a whole package set for a specific MPI implementation
  makeMpi = pkg: MPI: with super; {
    mpi = pkg;

    ga = callPackage ./ga { mpi=pkg; };

    osu-benchmark = callPackage ./osu-benchmark { mpi=pkg; };

    # scalapack is only valid with ILP32
    scalapackCompat = callPackage ./scalapack { blas = self.openblasCompat; mpi=pkg; };
    scalapack = callPackage ./scalapack { blas = self.openblasCompat; mpi=pkg; };

    cp2k = callPackage ./cp2k { mpi=pkg; scalapack=MPI.scalapack; fftw=self.fftwOpt; };

    # Relativistic methods are broken with non-MKL libs
    bagel-openblas = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapack; };

    # mkl is the default.
    bagel-mkl = callPackage ./bagel { blas = self.mkl; mpi=pkg; };
    bagel-mkl-scl = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapack; };
    bagel = MPI.bagel-mkl;

    nwchem = callPackage ./nwchem { mpi=pkg; };

    openmolcas = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      openblas = self.openblas;
      mpi=pkg;
      ga=MPI.ga;
    };

    openmolcas-mkl = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      openblas = self.mkl;
      mpi=pkg;
      ga=MPI.ga;
    };
  };

in with super;

{
  # Allow to provide a local download source for unfree packages
  requireFile = if srcurl == null then super.requireFile else
    { name, sha256, ... } :
    super.fetchurl {
      url = srcurl + "/" + name;
      sha256 = sha256;
    };

  # MPI packages sets
  openmpiPkgs = makeMpi self.openmpi self.openmpiPkgs;

  mpichPkgs = makeMpi self.mpich2 self.mpichPkgs;

  mvapichPkgs = makeMpi self.mvapich self.mvapichPkgs;

  ### Quantum Chem
  cp2k = self.openmpiPkgs.cp2k;

  bagel = self.openmpiPkgs.bagel;

  molden = super.molden.overrideDerivation (oa: {
    src = super.fetchurl {
      url = "ftp://ftp.cmbi.ru.nl/pub/molgraph/molden/molden${oa.version}.tar.gz";
      sha256 = "1sfv04zv6z5ga739nf6929442mr4dryprrf1ih1vckqbx2wlv8k5";
    };
  });

  ergoscf = callPackage ./ergoscf { };

  # fix a bug in the header file, which causes bagel to fail
  libxc = super.libxc.overrideDerivation (oa: {
    postFixup = ''
      sed -i '/#include "config.h"/d' $out/include/xc.h
    '';
  });

  nwchem = self.openmpiPkgs.nwchem;

  mctdh = callPackage ./mctdh { };

  # gfortran7 segfaults on one fortran file
  mesa = callPackage ./mesa {
    openblas=(openblas.override { gfortran=gfortran6; });
    gfortran = gfortran6;
  };

  molpro = callPackage ./molpro { token=licMolpro; };

  molcas = self.openmpiPkgs.openmolcas;

  molcas-mkl = self.openmpiPkgs.openmolcas-mkl;

  qdng = callPackage ./qdng { fftw=self.fftwOpt; };

  sharc = callPackage ./sharc { molcas=self.molcas-mkl; fftw=self.fftwOpt; };

  sharc-v1 = callPackage ./sharc/V1.nix { localFile=lF; };


  # Unsuported. Scalapack does not work with ILP64
  # scalapack = callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ### Optmized HPC libs

  # Provide an optimized fftw library.
  # Overriding fftw completely causes a mass rebuild!
  fftwOpt = if optAVX then
    fftw.overrideDerivation ( oldAttrs: {
    configureFlags = oldAttrs.configureFlags
      ++ [ "--enable-avx" "--enable-avx2" "--enable-avx512" "--enable-fma" ];
  })
  else
    super.fftw;

  # Causes a lot of rebuilds
  openblasCompat = if optAVX then
    callPackage ./openblas { blas64 = false; target="SKYLAKEX"; }
  else
    super.openblasCompat;

  openblas = if optAVX then
    callPackage ./openblas { target="SKYLAKEX"; }
  else
    super.openblas;

  ### HPC libs and Tools

  ibsim = callPackage ./ibsim { };

  # impi = callPackage ./impi { localFile = lF; };

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

  mvapich = callPackage ./mvapich { };

  openshmem = callPackage ./openshmem { };

  openshmem-smp = self.openshmem;

  openshmem-udp = callPackage ./openshmem { conduit="udp"; };

  openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

  openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

  osss-ucx = callPackage ./osss-ucx { };

  sos = callPackage ./sos { };

  pmix = callPackage ./pmix { };

  ucx = callPackage ./ucx { enableOpt=true; };
}


