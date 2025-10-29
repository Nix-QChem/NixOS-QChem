final: prev:

let

  cfg =
    if (builtins.hasAttr "qchem-config" prev.config) then
      (import ./cfg.nix) prev.config.qchem-config
    else
      (import ./cfg.nix) { allowEnv = true; }; # if no config is given allow env

  inherit (prev) lib;
  qlib = import ./lib.nix { inherit lib; };

  # stdenv with CPU flags
  optStdenv = qlib.makeOptStdenv final.stdenv cfg.optArch "";

  # stdenv with extra optimization flags, use selectively
  aggressiveStdenv = qlib.makeOptStdenv final.stdenv cfg.optArch "-O3 -fomit-frame-pointer -ftree-vectorize";

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
      "${subset}" = optUpstream
        // (qlib.pkgs-by-name callPackage ./pkgs/by-name)
        // {

        pkgs = final;

        inherit callPackage;
        inherit aggressiveStdenv;

        # For chemps2
        hdf5-full = self.hdf5.override {
          cppSupport = true;
          fortranSupport = true;
        };

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
        ambertools = super.python311.pkgs.toPythonApplication self.python311.pkgs.ambertools;

        autodock-vina = callPackage ./pkgs/apps/autodock-vina {
          boost = final.boost182;
        };

        autoint = super.python3.pkgs.toPythonApplication self.python3.pkgs.pyphspu;

        bagel-serial = callPackage ./pkgs/by-name/bagel/package.nix {
          enableMpi = false;
        };

        cefine = self.nullable self.turbomole (callPackage ./pkgs/by-name/cefine/package.nix { });

        cfour = callPackage ./pkgs/by-name/cfour/package.nix {
          blas = final.blas-ilp64;
          lapack = final.lapack-ilp64;
        };

        chemps2 = callPackage ./pkgs/apps/chemps2 { };

        crest = callPackage ./pkgs/by-name/crest/package.nix {
          # Requires a newer version of tblite. Can likely be removed with next
          # tblite release
          tblite = super.tblite.overrideAttrs (old: {
            patches = [ ];
            src = super.fetchFromGitHub {
              owner = "tblite";
              repo = "tblite";
              rev = "4556e28f391573b3c80c94beb7c56313005d5269";
              hash = "sha256-JmTEnvYqA73vmWQe4cpjvp6/Wwb+elSMDdHTPwD3/jc=";
            };
          });
        };

        dice = callPackage ./pkgs/by-name/dice/package.nix {
          boost = self.boost-mpi;
        };

        dirac = callPackage ./pkgs/by-name/dirac/package.nix {
          inherit (self) exatensor;
        };

        exchcxx = callPackage ./pkgs/by-name/exchcxx/package.nix {
          inherit cfg;
          libxc = self.libxc_7;
        };

        gamess-us = callPackage ./pkgs/by-name/gamess-us/package.nix {
          gfortran = final.gfortran14;
        };

        gator = super.python3.pkgs.toPythonApplication self.python3.pkgs.gator;

        gau2grid = super.python3.pkgs.toPythonApplication self.python3.pkgs.gau2grid;

        gauxc = callPackage ./pkgs/by-name/gauxc/package.nix {
          inherit cfg;
        };

        iboview = prev.libsForQt5.callPackage ./pkgs/apps/iboview { };

        # Molcas with optimisation
        molcas = self.openmolcas;

        # Molcas with LibWFA support. That disables the EXPBAS module, though.
        molcasWfa = self.molcas.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ self.chemps2 ];
          cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DWFA=ON" ];

          # Needed by libwfa
          env.NIX_CFLAGS_COMPILE = "-std=c++14";

          prePatch = ''
            rm -r External/libwfa
            cp -r ${self.libwfa.src} External/libwfa
            chmod -R u+w External/
          '';
        });

        # Molcas with DICE for HeatBath CI
        molcasDice = self.molcas.overrideAttrs (oldAttrs: {
          propagatedUserEnvPkgs = [ self.dice ];
        });

        # Molcas with Neci support for QMC CI solvers including GAS
        molcasNeci = self.molcas.overrideAttrs (oldAttrs: {
          propagatedUserEnvPkgs = [ self.neci ];
        });

        moltemplate = super.python3.pkgs.toPythonApplication self.python3.pkgs.moltemplate;

        osu-benchmark = callPackage ./pkgs/by-name/osu-benchmark/package.nix {
          # OSU benchmark fails with C++ binddings enabled
          mpi = self.mpi.overrideAttrs (x: {
            configureFlags = super.lib.remove "--enable-mpi-cxx" x.configureFlags;
          });
        };

        pegamoid = self.python3.pkgs.callPackage ./pkgs/apps/pegamoid { };

        pdbfixer = super.python3.pkgs.toPythonApplication self.python3.pkgs.pdbfixer;

        polyply = super.python3.pkgs.toPythonApplication self.python3.pkgs.polyply;

        psi4 = super.python3.pkgs.toPythonApplication self.python3.pkgs.psi4;

        pysisyphus = super.python3.pkgs.toPythonApplication self.python3.pkgs.pysisyphus;

        q-chem-installer = callPackage ./pkgs/apps/q-chem/installer.nix { };

        qdng = callPackage ./pkgs/by-name/qdng/package.nix {
          stdenv = aggressiveStdenv;
          protobuf = final.protobuf_21;
        };

        qmcpack = super.python3.pkgs.toPythonApplication self.python3.pkgs.qmcpack;

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

        theodore = super.python3.pkgs.toPythonApplication self.python3.pkgs.theodore;

        turbomole78 = callPackage ./pkgs/by-name/turbomole/package.nix { version = "7.8.1"; };

        veloxchem = super.python3.pkgs.toPythonApplication self.python3.pkgs.veloxchem;

        vmd =
          if cfg.useCuda
          then callPackage ./pkgs/apps/vmd/binary.nix { }
          else callPackage ./pkgs/apps/vmd { }
        ;

        vmd-python = super.python311.pkgs.toPythonApplication self.python311.pkgs.vmd-python;

        wfaMolcas = self.libwfa.override { buildMolcasExe = true; };

        wfoverlap = callPackage ./pkgs/by-name/wfoverlap/package.nix {
          blas = final.blas-ilp64;
          lapack = final.lapack-ilp64;
        };

        xtb = callPackage ./pkgs/by-name/xtb/package.nix {
          meson = self.meson_1_7_2;
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


        ### Python packages
        python3 = super.python3.override (old: {
          packageOverrides = super.lib.composeExtensions (old.packageOverrides or (_: _: { })) (pythonOverrides cfg self super);
        });

        ### Python packages
        python312 = super.python312.override (old: {
          packageOverrides = super.lib.composeExtensions (old.packageOverrides or (_: _: { })) (pythonOverrides cfg self super);
        });

        ### Python packages
        python311 = super.python311.override (old: {
          packageOverrides = super.lib.composeExtensions (old.packageOverrides or (_: _: { })) (pythonOverrides cfg self super);
        });

        python2 = super.python2.override (old: {
          packageOverrides = super.lib.composeExtensions (old.packageOverrides or (_: _: { })) (pythonOverrides cfg self super);
        });

        #
        # Utilities
        #

        nixGL = callPackage ./pkgs/apps/nixgl { };

        writeScriptSlurm = callPackage ./builders/slurmScript.nix { };

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
