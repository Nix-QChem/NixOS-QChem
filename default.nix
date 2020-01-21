self: super:

let

  cfg = if (builtins.hasAttr "qchem-config" super.config) then
       super.config.qchem-config // (import ./cfg.nix)
     else
       (import ./cfg.nix);

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
    bagel-mkl = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=null; withScalapack=true; };
    bagel-openblas = callPackage ./bagel { blas = self.openblas; mpi=pkg; };
    bagel-mkl-scl = callPackage ./bagel { blas = self.mkl; mpi=pkg; scalapack=MPI.scalapack; withScalapack = true; };
    bagel = MPI.bagel-mkl;

    hpl = super.hpl.override { mpi=pkg; };

    mctdh = callPackage ./mctdh { useMPI=true; mpi=pkg; scalapack=MPI.scalapack; };

    nwchem = callPackage ./nwchem { mpi=pkg; };

    openmolcas = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      mpi=pkg;
      globalarrays=MPI.globalarrays;
    };

    openmolcasUnstable = callPackage ./openmolcas/unstable.nix {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      mpi=pkg;
      globalarrays=MPI.globalarrays;
    };
  };

  pythonOverrides = import ./pythonPackages.nix;

in with super;
{
  # Place composed config in pkgs
  config.qchem-config = cfg;

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

  openmpi = super.openmpi.overrideAttrs (x: {
    buildInputs = x.buildInputs ++ [ self.ucx ];
    # Supress compiler error accordig to ucx's instructions
    # https://github.com/openucx/ucx/wiki/OpenMPI-and-OpenSHMEM-installation-with-UCX#running-open-mpi-with-ucx
    configureFlags = x.configureFlags ++ [ "--enable-mca-no-build=btl-uct" ];
  });

  ### Quantum Chem
  chemps2 = callPackage ./chemps2 {};

  cp2k = self.openmpiPkgs.cp2k;

  bagel = self.openmpiPkgs.bagel;

  bagel-serial = callPackage ./bagel { mpi = null; blas = self.mkl; };

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

  mesa-qc = callPackage ./mesa {
    gfortran = gfortran6;
  };

  molpro = self.molpro19;

  molpro12 = callPackage ./molpro/2012.nix { token=cfg.licMolpro; };

  molpro15 = callPackage ./molpro/2015.nix { token=cfg.licMolpro; };

  molpro18 = callPackage ./molpro/2018.nix { token=cfg.licMolpro; };

  molpro19 = callPackage ./molpro { token=cfg.licMolpro; };

  molcas = self.openmpiPkgs.openmolcas;

  molcas1911 = self.molcas;

  molcasUnstable = self.openmpiPkgs.openmolcasUnstable;

  orca = callPackage ./orca { };

  qdng = callPackage ./qdng { fftw=self.fftwOpt; };

  sharc = self.sharcV2;

  sharc21 = self.sharcV21;

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

  sharcV21 = callPackage ./sharc/21.nix {
    bagel = self.bagel-serial;
    molcas = self.molcas;
    molpro = self.molpro12; # V2 only compatible with versions up to 2012
    useMolpro = if cfg.licMolpro != null then true else false;
    useOrca = if cfg.srcurl != null then true else false;
    fftw = self.fftwOpt;
  };

  vmd = callPackage ./vmd {};

  # Unsuported. Scalapack does not work with ILP64
  # scalapack = callPackage ./scalapack { mpi=self.openmpi-ilp64; };

  ## Other scientfic applicatons

  matlab = callPackage ./matlab { inherit (cfg) optpath; };


  octave = (super.octave.override {
    inherit (super)
      hdf5
      ghostscript
      glpk
      jdk
      suitesparse
      gnuplot
      qscintilla;
      qt = super.qt4;
  }).overrideAttrs (x: { preCheck = "export OMP_NUM_THREADS=4"; });

  ### Python packages

  python3 = super.python3.override { packageOverrides=pythonOverrides; };
  python2 = super.python2.override { packageOverrides=pythonOverrides; };


  ### Optmized HPC libs

  # Provide an optimized fftw library.
  # fftw supports instruction autodetect
  # Overriding fftw completely causes a mass rebuild!
  fftwOpt = fftw.overrideDerivation ( oldAttrs: {
    configureFlags = oldAttrs.configureFlags
    ++ [
      "--enable-avx"
      "--enable-avx2"
      "--enable-fma"
      "--enable-avx-128-fma"
    ];
    buildInputs = [ self.gfortran ];
  });

  # For molcas and chemps2
  hdf5-full = hdf5.override {
    cpp = true;
    inherit gfortran;
  };

  ### HPC libs and Tools

  ibsim = callPackage ./ibsim { };

  hwloc-x11 = super.hwloc.override { x11Support= true; };

  libfabric = callPackage ./libfabric { };

  libcint = callPackage ./libcint { };

  libint2 = callPackage ./libint { optAVX = cfg.optAVX; };

  # Needed for CP2K
  libint1 = callPackage ./libint/1.nix { };


  # libint configured for bagel
  # See https://github.com/evaleev/libint/wiki#bagel
  libint-bagel = callPackage ./libint { cfg = [
    "--enable-eri=1"
    "--enable-eri3=1"
    "--enable-eri2=1"
    "--with-max-am=6"
    "--with-eri3-max-am=6"
    "--with-eri2-max-am=6"
    "--disable-unrolling"
    "--enable-generic-code"
    "--with-cartgauss-ordering=bagel"
    "--enable-contracted-ints"
  ] ++ lib.optional cfg.optAVX "--enable-fma"
  ;};

  libxsmm = callPackage ./libxsmm { optAVX = cfg.optAVX; };

  mvapich = callPackage ./mvapich { };

  openshmem = callPackage ./openshmem { };

  openshmem-smp = self.openshmem;

  openshmem-udp = callPackage ./openshmem { conduit="udp"; };

  openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

  openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

  osss-ucx = callPackage ./osss-ucx { };

  sos = callPackage ./sos { };

  pmix = callPackage ./pmix { };

  spglib = callPackage ./spglib {};

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

  #
  # A wrapper to enforce license checkouts with slurm
  #
  slurmLicenceWrapper = { name, license, exe, runProg } : writeShellScriptBin exe ''
    if [ -z "$SLURM_JOB_ID" ]; then
      echo "${name} can only be run in a slurm environment"
      echo
      echo "Don't forget to check out a license by adding '-L ${license} to srun/sbatch/etc."
      exit
    fi

    licName="${license}"

    lics=`scontrol show job $SLURM_JOB_ID | grep Licenses | sed 's/.*Licenses=\(.*\) .*/\1/'`

    licsFound=`echo "$lics"x | grep -e "''${licName}x"`

    if [ -n "$licsFound" ]; then
      echo "Licenses checked out. Running ${name}..."
      ${runProg}
    else
      echo "No ${name} license checked out. Aborting!"
    fi
  '';

}


