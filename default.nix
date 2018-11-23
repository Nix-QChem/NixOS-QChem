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

    scalapackCompat = callPackage ./scalapack { blas = self.openblasCompat; mpi=pkg; };

    scalapackCompat-mkl = callPackage ./scalapack { blas = self.mkl; mpi=pkg; };

    cp2k = callPackage ./cp2k { mpi=pkg; scalapack=MPI.scalapackCompat; };

    # Relativistic methods are broken with non-MKL libs
    bagel-openblas = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapackCompat; };

    # mkl is the default.
    bagel-mkl = callPackage ./bagel { blas = self.mkl; mpi=pkg; };
    bagel-mkl-scl = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapackCompat; };
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
  openmpiPkgs = makeMpi self.openmpi self.openmpiPkgs;

  mpichPkgs = makeMpi self.mpich2 self.mpichPkgs;

  mvapichPkgs = makeMpi self.mvapich self.mvapichPkgs;

#  openmpi = super.openmpi.overrideAttrs (oa: {
#    configureFlags = oa.configureFlags ++ [
#      "--with-pmix=${self.pmix}"
#      "--with-pmi=${self.pmix}"
#      "--with-libevent=${libevent.dev}"
#      "--with-libevent-libdir=${libevent}/lib"
#    ];
#    buildInputs = oa.buildInputs ++ [ self.pmix super.openssl ];
#  });

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

  gamess = callPackage ./gamess { localFile=lF; mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { localFile=lF; mathlib=self.mkl; useMkl = true; };

  # fix a bug in the header file, which causes bagel to fail
  libxc = super.libxc.overrideDerivation (oa: {
    postFixup = ''
      sed -i '/#include "config.h"/d' $out/include/xc.h
    '';
  });

  nwchem = self.openmpiPkgs.nwchem;

  molpro = callPackage ./molpro { localFile=lF; token=licMolpro; };

  molcas = self.openmpiPkgs.openmolcas;

  molcas-mkl = self.openmpiPkgs.openmolcas-mkl;

  qdng = callPackage ./qdng { localFile=lF; fftw=self.fftw; };

  sharc = callPackage ./sharc { molcas=self.molcas-mkl; };

  sharc-v1 = callPackage ./sharc/V1.nix { localFile=lF; };


  # Unsuported. Scalapack does not work with ILP64
  # scalapack = callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ### HPC libs and Tools

  fftw = if optAVX then
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

  openblasCompat = callPackage ./openblas { blas64 = false; target="SKYLAKEX"; };
  openblas = callPackage ./openblas {  target="SKYLAKEX"; };

  openmpi-ilp64 = openmpi.overrideDerivation ( oldAttrs: {
    FCFLAGS="-fdefault-integer-8";
    configureFlags = oldAttrs.configureFlags ++ [ "--with-pmix" ];
  });

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


