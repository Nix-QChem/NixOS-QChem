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

  # build a package with specfific MPI implementation
  withMpi = pkg : mpi :
    super.appendToName mpi.name (pkg.override { mpi = mpi; });

  # Build a whole package set for a specific MPI implementation
  makeMpi = pkg: MPI: with super; {
    mpi = pkg;

    ga = callPackage ./ga { mpi=pkg; };

    osu-benchmark = callPackage ./osu-benchmark { mpi=pkg; };

    scalapackCompat = callPackage ./scalapack { blas = self.openblas3Compat; mpi=pkg; };

    scalapackCompat-mkl = callPackage ./scalapack { blas = self.mkl; mpi=pkg; };

    # Relativistic methods are broken with non-MKL libs
    bagel-openblas = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapackCompat; };

    # mkl is the default.
    bagel-mkl = callPackage ./bagel { blas = self.mkl; mpi=pkg; };
    bagel-mkl-scl = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapackCompat; };
    bagel = MPI.bagel-mkl;

    nwchem = callPackage ./nwchem { mpi=pkg; };

    openmolcas = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      openblas = self.openblas3;
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
  openmpiPkgs = makeMpi
     (super.openmpi.overrideDerivation ( oldAttrs: {
       configureFlags = oldAttrs.configureFlags ++ [ "--with-pmix" ];
     })) self.openmpiPkgs;

  mpichPkgs = makeMpi self.mpich2 self.mpichPkgs;

  mvapichPkgs = makeMpi self.mvapich self.mvapichPkgs;

  ### Quantum Chem
  bagel = self.openmpiPkgs.bagel;

  cp2k = callPackage ./cp2k { };

  molden = callPackage ./molden { localFile=lF; };

  gamess = callPackage ./gamess { localFile=lF; mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { localFile=lF; mathlib=self.mkl; useMkl = true; };

  nwchem = self.openmpiPkgs.nwchem;

  molpro = callPackage ./molpro { localFile=lF; token=licMolpro; };

  molcas = self.openmpiPkgs.openmolcas;
  
  molcas-mkl = self.openmpiPkgs.openmolcas-mkl;

  qdng = callPackage ./qdng { localFile=lF; fftw=self.fftwOpt; };

  sharc = callPackage ./sharc { };
  
  sharc-v1 = callPackage ./sharc/V1.nix { localFile=lF; };


  # Unsuported. Scalapack does not work with ILP64
  # scalapack = callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ### HPC libs and Tools

  fftwOpt = if optAVX then
    fftw.overrideDerivation ( oldAttrs: {
    configureFlags = oldAttrs.configureFlags
      ++ [ "--enable-avx" "--enable-avx2" ];
  })
  else
    super.fftw;

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

  mkl = callPackage ./mkl { localFile=lF; };

  mvapich = callPackage ./mvapich { };

  openblas3Compat = callPackage ./openblas { blas64 = false; };
  openblas3 = callPackage ./openblas { };

  openmpi-ilp64 = openmpi.overrideDerivation ( oldAttrs: {
    FCFLAGS="-fdefault-integer-8";
    configureFlags = oldAttrs.configureFlags ++ [ "--with-pmix" ];
  });

  openmpi = self.openmpiPkgs.mpi;

  openshmem = callPackage ./openshmem { };

  openshmem-smp = self.openshmem;

  openshmem-udp = callPackage ./openshmem { conduit="udp"; };

  openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

  openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

  sos = callPackage ./sos { };

  ucx = callPackage ./ucx { };
}


