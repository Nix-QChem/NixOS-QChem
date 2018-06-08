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
  
in with super; 

{

  ### Quantum Chem
  bagel = callPackage ./bagel { openblas = self.openblas3Compat; scalapack=self.scalapackCompat; };
  
  bagel-mpich = callPackage ./bagel { mpi=mpich2; openblas = self.openblas3Compat; scalapack=self.scalapackCompat-mpich; };

  cp2k = callPackage ./cp2k { };
 
  molden = molden.overrideDerivation ( oldAttrs: {
    # Use a local version to overcome update dilema
    src = fetchurl {
      url = "${if srcurl == null
              then "ftp://ftp.cmbi.ru.nl/pub/molgraph/molden/"
              else srcurl}
              /molden5.8.tar.gz";
    sha256 = "1dwkkp83id2674iphn3cb7bmlsg0fm41f5dgkbcf0ygj044sqyx1";
    };
  });

  gamess = callPackage ./gamess { localFile=lF; mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { localFile=lF; mathlib=self.mkl; useMkl = true; };

  ga = callPackage ./ga { };
  
  ga-mpich = withMpi self.ga mpich2 ;
 
  nwchem = callPackage ./nwchem { };
  
  nwchem-mpich = callPackage ./nwchem { mpi=mpich2; };

  molpro = callPackage ./molpro { localFile=lF; token=licMolpro; };

  openmolcas = callPackage ./openmolcas {
    texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
    openblas = self.openblas3;
  };

  molcas = self.openmolcas;
 
  molcas-mpich = self.molcas.override { mpi = mpich2; ga = self.ga-mpich; };

  qdng = callPackage ./qdng { localFile=lF; fftw=self.fftwOpt; };

  sharc = callPackage ./sharc { };

  scalapackCompat = callPackage ./scalapack { openblas = self.openblas3Compat; };
  
  scalapackCompat-mpich = withMpi self.scalapackCompat mpich2;

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

  openblas3Compat = callPackage ./openblas { blas64 = false; };
  openblas3 = callPackage ./openblas { };

  openmpi-ilp64 = openmpi.overrideDerivation ( oldAttrs: {
    FCFLAGS="-fdefault-integer-8";
    configureFlags = oldAttrs.configureFlags ++ [ "--with-pmix" ];
  });

  openmpi = openmpi.overrideDerivation ( oldAttrs: {
    configureFlags = oldAttrs.configureFlags ++ [ "--with-pmix" ];
  });

  openshmem = callPackage ./openshmem { };

  openshmem-smp = self.openshmem;

  openshmem-udp = callPackage ./openshmem { conduit="udp"; };

  openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

  openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

  sos = callPackage ./sos { };

  ucx = callPackage ./ucx { };
}


