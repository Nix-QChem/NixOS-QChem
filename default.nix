self: super:

let

  cfg = import ./cfg.nix;

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
      CFLAGS = super.lib.optionalString cfg.optAVX  "-O3 -mavx2 -mavx -msse2";
      FFLAGS = super.lib.optionalString cfg.optAVX  "-O3 -mavx2 -mavx -msse2";
    });

    scalapackCompat = MPI.scalapack;

    cp2k = callPackage ./cp2k {
      mpi=pkg;
      scalapack=MPI.scalapack;
      fftw=self.fftwOpt;
      optAVX = cfg.optAVX;
    };

    # MKL is the default. Relativistic methods are broken with non-MKL libs
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

      cmakeFlags = x.cmakeFlags ++ [ "-DWFA=ON" ];

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

    openmolcasUnstable = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      mpi=pkg;
      globalarrays=MPI.globalarrays;
    };
  };

  pythonOverrides = import ./pythonPackages.nix;

in with super;

{
  # Allow to provide a local download source for unfree packages
  requireFile = if cfg.srcurl == null then super.requireFile else
    { name, sha256, ... } :
    super.fetchurl {
      url = cfg.srcurl + "/" + name;
      sha256 = sha256;
    };

  # MPI packages sets
  openmpiPkgs = makeMpi self.openmpi self.openmpiPkgs;

  mpichPkgs = makeMpi self.mpich2 self.mpichPkgs;

  mvapichPkgs = makeMpi self.mvapich self.mvapichPkgs;

  ### Quantum Chem
  cp2k = self.openmpiPkgs.cp2k;

  bagel = self.openmpiPkgs.bagel;

  gaussian = callPackage ./gaussian { inherit (cfg) optpath; };

  gaussview = callPackage ./gaussview { };

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

  mesa-qc = callPackage ./mesa { };

  molpro = self.molpro19;

  molpro12 = callPackage ./molpro/2012.nix { token=cfg.licMolpro; };

  molpro15 = callPackage ./molpro/2015.nix { token=cfg.licMolpro; };

  molpro19 = callPackage ./molpro { token=cfg.licMolpro; };


  molcas = self.openmpiPkgs.openmolcas;

  molcasUnstable = self.openmpiPkgs.openmolcasUnstable;

  orca = callPackage ./orca { };

  qdng = callPackage ./qdng { fftw=self.fftwOpt; };

  sharc = self.sharcV2;

  sharcV1 = callPackage ./sharc/V1.nix {
    molcas = self.molcas;
    molpro = self.molpro12; # V1 only compatible with versions up to 2012
    useMolpro = if cfg.licMolpro != null then true else false;
    fftw = self.fftwOpt;
  };

  sharcV2 = callPackage ./sharc {
    molcas = self.molcas;
    molpro = self.molpro12; # V2 only compatible with versions up to 2012
    useMolpro = if cfg.licMolpro != null then true else false;
    fftw = self.fftwOpt;
  };

  vmd = callPackage ./vmd {};

  # Unsuported. Scalapack does not work with ILP64
  # scalapack = callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ## Other scientfic applicatons

  matlab = callPackage ./matlab { inherit (cfg) optpath; };

  ### Python packages

  python3 = super.python3.override { packageOverrides=pythonOverrides; };
  python2 = super.python2.override { packageOverrides=pythonOverrides; };


  ### Optmized HPC libs

  # Provide an optimized fftw library.
  # Overriding fftw completely causes a mass rebuild!
  fftwOpt = if cfg.optAVX then
    fftw.overrideDerivation ( oldAttrs: {
    configureFlags = oldAttrs.configureFlags
      ++ [ "--enable-avx" "--enable-avx2" "--enable-fma" ];
    buildInputs = [ self.gfortran ];
  })
  else
    super.fftw;

  ### HPC libs and Tools

  ibsim = callPackage ./ibsim { };

  hwloc-x11 = super.hwloc.override { x11Support= true; };

  libfabric = callPackage ./libfabric { };

  libcint = callPackage ./libcint { };

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


