{ srcurl ? null  # base url for non-free packages
, licMolpro ?  null # string containing the license token
, optAVX ? true # turn of AVX optimizations
} :
self: super:


let
  # makeFlags filter for openblas
  obMkfCleaner = makeFlags:
    map (x: if (x == "DYNAMIC_ARCH=1") then "DYNAMIC_ARCH=0" else
      if (x == "TARGET=ATHLON") then "TARGET=HASWELL" else x
    ) makeFlags;

  # build a package with specfific MPI implementation
  withMpi = pkg : mpi :
    super.appendToName mpi.name (pkg.override { mpi = mpi; });

  # Build a whole package set for a specific MPI implementation
  makeMpi = pkg: MPI: with super; {
    mpi = pkg;

    globalarrays = super.globalarrays.override { openmpi=pkg; };

    osu-benchmark = callPackage ./osu-benchmark { mpi=pkg; };

    # scalapack is only valid with ILP32
    scalapack = (super.scalapack.override { mpi=pkg; }).overrideAttrs
    ( x: {
      CFLAGS = "-O3 -mavx2 -mavx -msse2";# + super.lib.optionalString optAVX " -mavx512f -mavx512cd";
      FFLAGS = "-O3 -mavx2 -mavx -msse2";# + super.lib.optionalString optAVX " -mavx512f -mavx512cd";
    });

    scalapackCompat = MPI.scalapack;

    cp2k = callPackage ./cp2k { mpi=pkg; scalapack=MPI.scalapack; fftw=self.fftwOpt; };

    # Relativistic methods are broken with non-MKL libs
    bagel-openblas = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapack; };

    # mkl is the default.
    bagel-mkl = callPackage ./bagel { blas = self.mkl; mpi=pkg; };
    bagel-mkl-scl = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapack; };
    bagel = MPI.bagel-mkl;

    hpl = callPackage ./hpl { mpi=pkg; };

    mctdh = callPackage ./mctdh { useMPI=true; mpi=pkg; scalapack=MPI.scalapack; };

    nwchem = callPackage ./nwchem { mpi=pkg; };

    openmolcas = (super.openmolcas.override {
      openmpi=pkg;
      globalarrays=MPI.globalarrays;
    }).overrideAttrs (x :
    let
      srcLibwfa = fetchFromGitHub {
        owner = "libwfa";
        repo = "libwfa";
        rev = "efd3d5bafd403f945e3ea5bee17d43e150ef78b2";
        sha256 = "0qzs8s0pjrda7icws3f1a55rklfw7b94468ym5zsgp86ikjf2rlz";
      };
    in {

      patches = [ (fetchpatch {
        name = "excessive-h5-size"; # Can be removed in the update
        url = "https://gitlab.com/Molcas/OpenMolcas/commit/73fae685ed8a0c41d5109ce96ade31d4924c3d9a.patch";
        sha256 = "1wdk1vpc0y455dinbxhc8qz3fh165wpdcrhbxia3g2ppmmpi11sc";
      }) ];

      prePatch = ''
        rm -r External/libwfa
        cp -r ${srcLibwfa} External/libwfa
        chmod -R u+w External/
      '';

      doInstallCheck = true;

      installCheckPhase = ''
         #
         # Minimal check if installation runs properly
         #

         export MOLCAS_WORKDIR=./
         inp=water

         cat << EOF > $inp.xyz
         3
         Angstrom
         O       0.000000  0.000000  0.000000
         H       0.758602  0.000000  0.504284
         H       0.758602  0.000000 -0.504284
         EOF

         cat << EOF > $inp.inp
         &GATEWAY
         coord=water.xyz
         basis=sto-3g
         &SEWARD
         &SCF
         EOF

         $out/bin/pymolcas $inp.inp > $inp.out

         echo "Check for sucessful run:"
         grep "Happy landing" $inp.status
         echo "Check for correct energy:"
         grep "Total SCF energy" $inp.out | grep 74.880174
      '';
    });

    #openmolcas-mkl = MPI.openmolcas.override {
    #  openblas = self.mkl;
    #};
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

  gaussview = callPackage ./gaussview { };

  molden = super.molden.overrideDerivation (oa: {
    src = super.fetchurl {
      url = "ftp://ftp.cmbi.ru.nl/pub/molgraph/molden/molden5.9.3.tar.gz";
      sha256 = "18fz44g7zkm0xcx3w9hm049jv13af67ww7mb5b3kdhmza333a16q";
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

  mctdh = callPackage ./mctdh { mpi=null; };

  mctdh-mpi = self.openmpiPkgs.mctdh;

  # gfortran7 segfaults on one fortran file
  mesa = callPackage ./mesa {
    openblas=(openblas.override { gfortran=gfortran6; });
    gfortran = gfortran6;
  };

  molpro = callPackage ./molpro { token=licMolpro; };

  molcas = self.openmpiPkgs.openmolcas;

  #molcas-mkl = self.openmpiPkgs.openmolcas-mkl;

  qdng = callPackage ./qdng { fftw=self.fftwOpt; };

  sharc = callPackage ./sharc { molcas=self.molcas; fftw=self.fftwOpt; };

  # Unsuported. Scalapack does not work with ILP64
  # scalapack = callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ### Optmized HPC libs

  # Provide an optimized fftw library.
  # Overriding fftw completely causes a mass rebuild!
  fftwOpt = if optAVX then
    fftw.overrideDerivation ( oldAttrs: {
    configureFlags = oldAttrs.configureFlags
      ++ [ "--enable-avx" "--enable-avx2" "--enable-fma" ];
    buildInputs = [ self.gfortran ];
  })
  else
    super.fftw;

  # Causes a lot of rebuilds
  openblasCompat = if optAVX then
    super.openblasCompat.overrideDerivation ( oa : {
      makeFlags = obMkfCleaner oa.makeFlags;
    })
  else
    super.openblasCompat;

  openblas = if optAVX then
    super.openblas.overrideDerivation ( oa : {
      makeFlags = obMkfCleaner oa.makeFlags;
    })
  else
    super.openblas;

  ### HPC libs and Tools

  ibsim = callPackage ./ibsim { };

  hpl = self.openmpiPkgs.hpl;

  libfabric = callPackage ./libfabric { };

  libint = callPackage ./libint { };

  # Needed for CP2K
  libint1 = callPackage ./libint/1.nix { };

  libint-bagel = callPackage ./libint { cfg = [
    "--esuper.nable-eri=1"
    "--enable-eri3=1"
    "--enable-eri2=1"
    "--with-max-am=6"
    "--with-cartgauss-ordering=bagel"
    "--enable-contracted-ints"
  ];};

  libxsmm = callPackage ./libxsmm { };

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

  # Utilities
  writeScriptSlurm =
    { name
    , text
    , N ? 1     # No. of nodes
    , n ? null  # No. of task
    , c ? null  # No. of CPUs per task
    , J ? null  # Job name
    # shell to use
    , shell ? "bash"
    # if set will use nix-shell as script interpreter
    , nixShellArgs ? null
    } :
    with super.lib; super.writeTextFile {
      inherit name;
      executable = true;
      text = ''
        #!/usr/bin/env ${if nixShellArgs == null then "${shell}" else "nix-shell"}
        #${optionalString (nixShellArgs != null) "#!nix-shell -i ${shell} ${nixShellArgs}"}
        #SBATCH -J ${if (J != null) then J else name}
        #SBATCH -N ${toString N}
        #${optionalString (n != null) "SBATCH -n ${toString n}"}
        #${optionalString (c != null) "SBATCH -c ${toString c}"}
        ${text}
      '';
    };

}


