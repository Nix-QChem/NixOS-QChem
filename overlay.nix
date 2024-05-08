final: prev:

let

  cfg =
    if (builtins.hasAttr "qchem-config" prev.config) then
      (import ./cfg.nix) prev.config.qchem-config
    else
      (import ./cfg.nix) { allowEnv = true; }; # if no config is given allow env

  inherit (prev) lib;

  # Create a stdenv with CPU optimizations
  makeOptStdenv = stdenv: arch: extraCflags: if arch == null then stdenv else
    stdenv.override {
      name = stdenv.name + "-${arch}";

      # Make sure respective CPU features are set
      hostPlatform = stdenv.hostPlatform //
        lib.mapAttrs (p: a: a arch) lib.systems.architectures.predicates;

      # Add additional compiler flags
      extraAttrs = {
        mkDerivation = args: (stdenv.mkDerivation args).overrideAttrs (old: {
          env.NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "")
            + " -march=${arch} -mtune=${arch} " + extraCflags;
        });
      };
    };

  # stdenv with CPU flags
  optStdenv = makeOptStdenv final.stdenv cfg.optArch "";

  # stdenv with extra optimization flags, use selectively
  aggressiveStdenv = makeOptStdenv final.stdenv cfg.optArch "-O3 -fomit-frame-pointer -ftree-vectorize";


  #
  # Our package set
  #
  overlay = subset: extra:
    let
      super = prev;
      self = final."${subset}";
      callPackage = super.lib.callPackageWith (final // self);
      pythonOverrides = (import ./pythonPackages.nix) subset;

      optUpstream = import ./nixpkgs-opt.nix cfg final prev self optStdenv;

    in
    {
      "${subset}" = optUpstream // {

        pkgs = final;

        inherit callPackage;
        inherit aggressiveStdenv;

        #
        # Upstream overrides
        #

        # For molcas and chemps2
        hdf5-full = self.hdf5.override {
          cppSupport = true;
          fortranSupport = true;
        };

        fftw-mpi = self.fftw.override { enableMpi = true; };

        # Non-GUI version
        octave-opt = (final.octave.override {
          stdenv = self.aggressiveStdenv;
          enableJava = true;
          jdk = super.jdk8;
          inherit (final)
            hdf5
            ghostscript
            glpk
            suitesparse
            gnuplot;
          inherit (self)
            fftw
            arpack;
        }).overrideAttrs (x: { preCheck = "export OMP_NUM_THREADS=4"; });

        # GUI version
        octave = (final.octaveFull.override {
          enableJava = true;
          jdk = super.jdk8;
          inherit (final)
            hdf5
            ghostscript
            glpk
            suitesparse
            gnuplot;
          inherit (self)
            fftw
            arpack;
        }).overrideAttrs (x: { preCheck = "export OMP_NUM_THREADS=4"; });

        # Allow to provide a local download source for unfree packages
        requireFile = if cfg.srcurl == null then super.requireFile else
        { name, sha256, ... }:
        super.fetchurl {
          url = cfg.srcurl + "/" + name;
          inherit sha256;
        };

        # Return null if x == null otherwise return the argument
        nullable = x: ret: if x == null then null else ret;

        #
        # Applications
        #
        ambertools = super.python3.pkgs.toPythonApplication self.python3.pkgs.ambertools;

        autodock-vina = callPackage ./pkgs/apps/autodock-vina { };

        autoint = super.python3.pkgs.toPythonApplication self.python3.pkgs.pyphspu;

        bagel = callPackage ./pkgs/apps/bagel {
        };

        bagel-serial = callPackage ./pkgs/apps/bagel {
          enableMpi = false;
        };

        cefine = self.nullable self.turbomole (callPackage ./pkgs/apps/cefine { });

        cfour = callPackage ./pkgs/apps/cfour {
          blas = final.blas-ilp64;
          lapack = final.lapack-ilp64;
        };

        chemps2 = callPackage ./pkgs/apps/chemps2 { };

        cpcm-x = callPackage ./pkgs/lib/cpcm-x { };

        crest = callPackage ./pkgs/apps/crest {
          # Requires a newer version of tblite. Can likely be removed with next
          # tblite release
          tblite = super.tblite.overrideAttrs (old: {
            patches = [ ];
            src = super.fetchFromGitHub {
              owner = "tblite";
              repo = "tblite";
              rev = "1bd936ca81f6f9ec9bbe65e32bc422ff5388571b";
              hash = "sha256-ywXpnKU5CkPSp4zfJkFvrN09ptjt3tqq2zSqPcHAv6E=";
            };
          });
        };

        dalton = callPackage ./pkgs/apps/dalton { };

        dftd3 = callPackage ./pkgs/apps/dft-d3 { };

        dftbplus = super.python3.pkgs.toPythonApplication self.python3.pkgs.dftbplus;

        dirac = callPackage ./pkgs/apps/dirac {
          inherit (self) exatensor;
        };

        dkh = callPackage ./pkgs/apps/dkh { };

        et = callPackage ./pkgs/apps/et { };

        exatensor = callPackage ./pkgs/apps/exatensor { };

        exciting = callPackage ./pkgs/apps/exciting {
          gfortran = final.gfortran13;
        };

        gabedit = callPackage ./pkgs/apps/gabedit { };

        gamess-us = callPackage ./pkgs/apps/gamess-us {
          blas = final.blas-ilp64;
          gfortran = final.gfortran9;
        };

        gator = super.python3.pkgs.toPythonApplication self.python3.pkgs.gator;

        gaussview = callPackage ./pkgs/apps/gaussview { };

        gdma = callPackage ./pkgs/apps/gdma { };

        gfn0 = callPackage ./pkgs/apps/gfn0 { };

        gfnff = callPackage ./pkgs/apps/gfnff { };

        iboview = prev.libsForQt5.callPackage ./pkgs/apps/iboview { };

        janpa = callPackage ./pkgs/apps/janpa { };

        luscus = callPackage ./pkgs/apps/luscus { };

        macroqc = callPackage ./pkgs/apps/macroqc { };

        mctdh = callPackage ./pkgs/apps/mctdh { };

        molcas = let
          molcasOpt = prev.openmolcas.override {
            stdenv = aggressiveStdenv;
            hdf5-cpp = self.hdf5-full;
          };
        in molcasOpt.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ self.chemps2 ];
          cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DWFA=ON" ];

          # Needed by libwfa
          CXXFLAGS = [ "-DH5_USE_110_API" ];

          prePatch = ''
            rm -r External/libwfa
            cp -r ${self.libwfa.src} External/libwfa
            chmod -R u+w External/
          '';
        });

        moltemplate = super.python3.pkgs.toPythonApplication self.python3.pkgs.moltemplate;

        mpifx = callPackage ./pkgs/lib/mpifx { };

        mrcc = callPackage ./pkgs/apps/mrcc { };

        mrchem = callPackage ./pkgs/apps/mrchem { };

        mt-dgemm = callPackage ./pkgs/apps/mt-dgemm { };

        multiwfn = callPackage ./pkgs/apps/multiwfn { };

        gmultiwfn = callPackage ./pkgs/apps/gmultiwfn { };

        numsa = callPackage ./pkgs/lib/numsa { };

        orca = callPackage ./pkgs/apps/orca { };

        orient = callPackage ./pkgs/apps/orient { };

        osu-benchmark = callPackage ./pkgs/apps/osu-benchmark {
          # OSU benchmark fails with C++ binddings enabled
          mpi = self.mpi.overrideAttrs (x: {
            configureFlags = super.lib.remove "--enable-mpi-cxx" x.configureFlags;
          });
        };

        packmol = callPackage ./pkgs/apps/packmol { };

        pegamoid = self.python3.pkgs.callPackage ./pkgs/apps/pegamoid { };

        pdbfixer = super.python3.pkgs.toPythonApplication self.python3.pkgs.pdbfixer;

        plt2cub = callPackage ./pkgs/apps/plt2cub { };

        poltype2 = callPackage ./pkgs/apps/poltype2 { };

        polyply = super.python3.pkgs.toPythonApplication self.python3.pkgs.polyply;

        psi4 = super.python3.pkgs.toPythonApplication self.python3.pkgs.psi4;

        pysisyphus = super.python3.pkgs.toPythonApplication self.python3.pkgs.pysisyphus;

        q-chem-installer = callPackage ./pkgs/apps/q-chem/installer.nix { };

        qdng = callPackage ./pkgs/apps/qdng {
          stdenv = aggressiveStdenv;
          protobuf = final.protobuf3_21;
        };

        qmcpack = callPackage ./pkgs/apps/qmcpack { };

        salmon = callPackage ./pkgs/apps/salmon { };

        scalapackfx = callPackage ./pkgs/lib/scalapackfx { };

        sgroup = callPackage ./pkgs/apps/sgroup { };

        sharc-unwrapped = callPackage ./pkgs/apps/sharc/unwrapped.nix {
          hdf4 = super.hdf4.override {
            fortranSupport = true;
            szipSupport = true;
          };
        };

        # blank version
        sharc = callPackage ./pkgs/apps/sharc/default.nix {
          bagel = self.bagel-serial;
          molpro = self.molpro12; # V2 only compatible with versions up to 2012
          gaussian = if cfg.optpath != null then self.gaussian else null;
        };

        sharc-full = self.sharc.override {
          enableBagel = true;
          enableMolcas = true;
          enableMolpro = if self.molpro12 != null then true else false;
          enableOrca = if self.orca != null then true else false;
          enableTurbomole = if self.turbomole != null then true else false;
          enableGaussian = if self.gaussian != null then true else false;
        };

        sharc-bagel = self.sharc.override { enableBagel = true; };

        sharc-gaussian = with self; nullable gaussian (sharc.override { enableGaussian = true; });

        sharc-molcas = self.sharc.override { enableMolcas = true; };

        sharc-molpro = with self; nullable molpro12 (sharc.override { enableMolpro = true; });

        sharc-orca = with self; nullable orca (sharc.override { enableOrca = true; });

        sharc-turbomole = with self; nullable turbomole (sharc.override { enableTurbomole = true; });

        stream-benchmark = callPackage ./pkgs/apps/stream { };

        theodore = super.python3.pkgs.toPythonApplication self.python3.pkgs.theodore;

        tinker = callPackage ./pkgs/apps/tinker { };

        travis-analyzer = callPackage ./pkgs/apps/travis-analyzer { };

        turbomole = callPackage ./pkgs/apps/turbomole { };

        veloxchem = super.python3.pkgs.toPythonApplication self.python3.pkgs.veloxchem;

        vmd =
          if cfg.useCuda
          then callPackage ./pkgs/apps/vmd/binary.nix { }
          else callPackage ./pkgs/apps/vmd { }
        ;

        vmd-python = super.python3.pkgs.toPythonApplication self.python3.pkgs.vmd-python;

        vossvolvox = callPackage ./pkgs/apps/vossvolvox { };

        wfaMolcas = self.libwfa.override { buildMolcasExe = true; };

        wfoverlap = callPackage ./pkgs/apps/wfoverlap {
          blas = final.blas-ilp64;
          lapack = final.lapack-ilp64;
        };

        xtb = callPackage ./pkgs/apps/xtb {
          # XTB declares a tblite dependency >= 0.2.0 but actually requires > 0.3.0
          tblite = super.tblite.overrideAttrs (old: {
            patches = [ ];
            src = super.fetchFromGitHub {
              owner = "tblite";
              repo = "tblite";
              rev = "1bd936ca81f6f9ec9bbe65e32bc422ff5388571b";
              hash = "sha256-ywXpnKU5CkPSp4zfJkFvrN09ptjt3tqq2zSqPcHAv6E=";
            };
          });
        };

        xtb-iff = callPackage ./pkgs/apps/xtb-iff { };

        ### Python packages
        python3 = super.python3.override (old: {
          packageOverrides = super.lib.composeExtensions (old.packageOverrides or (_: _: { })) (pythonOverrides cfg self super);
        });

        python2 = super.python2.override (old: {
          packageOverrides = super.lib.composeExtensions (old.packageOverrides or (_: _: { })) (pythonOverrides cfg self super);
        });

        #
        # Libraries
        #

        amd-fftw = callPackage ./pkgs/lib/amd-fftw { };

        amd-scalapack = callPackage ./pkgs/lib/amd-scalapack { };

        libecpint = callPackage ./pkgs/lib/libecpint { };

        libefp = callPackage ./pkgs/lib/libefp { };

        libGDSII = callPackage ./pkgs/lib/libGDSII { };

        libtensor = callPackage ./pkgs/lib/libtensor { };

        libvdwxc = callPackage ./pkgs/lib/libvdwxc { };

        libwfa = callPackage ./pkgs/lib/libwfa { };

        mrcpp = callPackage ./pkgs/lib/mrcpp { };

        #
        # Utilities
        #

        nixGL = callPackage ./pkgs/apps/nixgl { };

        writeScriptSlurm = callPackage ./builders/slurmScript.nix { };

        slurm-tools = callPackage ./pkgs/apps/slurm-tools { };

        project-shell = callPackage ./pkgs/apps/project-shell { };

        # A wrapper to enforce license checkouts with slurm
        slurmLicenseWrapper = callPackage ./builders/licenseWrapper.nix { };

        # build bats tests
        batsTest = callPackage ./builders/batsTest.nix { };

        # build a benchmark script
        #benchmarkScript = callPackage ./builders/benchmark.nix { };

        # benchmark set builder
        benchmarks = callPackage ./benchmark/default.nix { };

        benchmarksets = callPackage ./tests/benchmark-sets.nix {
          inherit callPackage;
        };

        tests = with self; {
          cfour = nullable cfour (callPackage ./tests/cfour { });
          cp2k = callPackage ./tests/cp2k { };
          bagel = callPackage ./tests/bagel { };
          bagel-bench = callPackage ./tests/bagel/bench-test.nix { };
          dalton = callPackage ./tests/dalton { };
          hpcg = callPackage ./tests/hpcg { };
          hpl = callPackage ./tests/hpl { };
          molcas = callPackage ./tests/molcas { };
          molpro = nullable molpro (callPackage ./tests/molpro { });
          mrcc = nullable mrcc (callPackage ./tests/mrcc { });
          nwchem = callPackage ./tests/nwchem { };
          pyscf = callPackage ./tests/pyscf { };
          qdng = callPackage ./tests/qdng { };
          dgemm = callPackage ./tests/dgemm { };
          stream = callPackage ./tests/stream { };
          turbomole = nullable turbomole (callPackage ./tests/turbomole { });
          xtb = callPackage ./tests/xtb { };
        };

        testFiles =
          let
            batsDontRun = self.batsTest.override { overrideDontRun = true; };
          in
          builtins.mapAttrs (n: v: v.override { batsTest = batsDontRun; })
            self.tests;

        # provide null molpro attrs in case there is no license
        molpro = null;
        molpro12 = null;
        molpro-ext = null;

        q-chem = null;

        # Provide null gaussian attrs in case optpath is not set
        gaussian = null;
      } // lib.optionalAttrs (cfg.licMolpro != null) {

        #
        # Molpro packages
        #
        molpro = callPackage ./pkgs/apps/molpro { token = cfg.licMolpro; };

        molpro-pr = self.molpro.override { comm = "mpipr"; };

        molpro12 = callPackage ./pkgs/apps/molpro/2012.nix { token = cfg.licMolpro; };

        molpro-ext = callPackage ./pkgs/apps/molpro/custom.nix { token = cfg.licMolpro; };

      } // lib.optionalAttrs (cfg.licQChem != null) {
        q-chem = callPackage ./pkgs/apps/q-chem/default.nix {
          qchemLicensePath = cfg.licQChem;
        };
      } // lib.optionalAttrs (cfg.optpath != null) {
        #
        # Quirky packages that need to reside outside the nix store
        #
        gaussian = callPackage ./pkgs/apps/gaussian { inherit (cfg) optpath; };

        matlab = callPackage ./pkgs/apps/matlab { inherit (cfg) optpath; };

      } // extra;
    };

in
overlay cfg.prefix { }
