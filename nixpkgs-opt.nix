cfg: final: prev: self: optStdenv:

#
# Package set with upstream libraries
# and optimizations of upstream packages
#

with final;
let
  hp = optStdenv.hostPlatform;

  # like callPackage but with override instead
  recallPackage = pkg: inputs:
    pkg.override ((builtins.intersectAttrs pkg.override.__functionArgs set) // inputs);

  set = {
    stdenv = optStdenv;
    avogadro2 = recallPackage avogadro2 {};
    arpack = recallPackage arpack {};
    arpack-mpi = recallPackage arpack { useMpi = true; };
    boost-mpi = recallPackage boost {
      useMpi = true;
      inherit (self) mpi;
    };

    # This a modified version of the upstream override.
    cp2k =
      # CP2K requires all dependencies from the Grimme ecosystem to be build with
      # CMake instead of Meson. Unfortunately most other consumers require meson
      let
        grimmeCmake = final.lib.makeScope final.newScope (grimmeSelf: {
          mctc-lib = final.mctc-lib.override {
            buildType = "cmake";
            inherit (grimmeSelf) jonquil toml-f;
            inherit (self) stdenv;
          };

          toml-f = final.toml-f.override {
            buildType = "cmake";
            inherit (grimmeSelf) test-drive;
          };

          dftd4 = final.dftd4.override {
            buildType = "cmake";
            inherit (grimmeSelf) mstore mctc-lib multicharge;
            inherit (self) stdenv;
          };

          jonquil = final.jonquil.override {
            buildType = "cmake";
            inherit (grimmeSelf) toml-f test-drive;
          };

          mstore = final.mstore.override {
            buildType = "cmake";
            inherit (grimmeSelf) mctc-lib;
          };

          multicharge = final.multicharge.override {
            buildType = "cmake";
            inherit (grimmeSelf) mctc-lib mstore;
            inherit (self) stdenv;
          };

          test-drive = final.test-drive.override { buildType = "cmake"; };

          simple-dftd3 = final.simple-dftd3.override {
            buildType = "cmake";
            inherit (grimmeSelf) mctc-lib mstore toml-f;
            inherit (self) stdenv;
          };

          tblite = final.tblite.override {
            buildType = "cmake";
            inherit (grimmeSelf)
              mctc-lib
              mstore
              toml-f
              multicharge
              dftd4
              simple-dftd3
              ;
            inherit (self) stdenv;
          };

          sirius = final.sirius.override {
            inherit (grimmeSelf)
              mctc-lib
              toml-f
              multicharge
              dftd4
              simple-dftd3
              ;
            inherit (self) stdenv;
          };
        });
      in
      final.cp2k.override {
        inherit (grimmeCmake)
          toml-f
          dftd4
          simple-dftd3
          tblite
          sirius
        ;
        libxc = pkgs.libxc_7;
      };

    fftw = recallPackage fftw {};
    dkh = recallPackage dkh {};
    dftd4 = recallPackage dftd4 {};
    simple-dftd3 = recallPackage simple-dftd3 {};
    # Currently broken upstream. Put back after next upgrade
    # elpa = recallPackage elpa {};
    ergoscf = recallPackage ergoscf {};
    harminv = recallPackage harminv {};
    inherit (final) hdf5;
    hpl = recallPackage hpl {};
    hpcg = recallPackage hpcg {};
    i-pi = recallPackage i-pi {};
    gsl = recallPackage gsl {};
    gpaw = python3.pkgs.toPythonApplication (recallPackage python3.pkgs.gpaw {});
    libint = recallPackage libint {};
    libmbd = recallPackage libmbd {};
    libvori = recallPackage libvori {};
    libvdwxc = recallPackage libvdwxc {};
    libxc = recallPackage libxc {};
    libxc_7 = recallPackage libxc_7 {};
    mpb = recallPackage mpb {};
    meep = python3.pkgs.toPythonApplication (recallPackage python3.pkgs.meep {});
    mkl = recallPackage mkl {};
    molden = recallPackage molden {};
    mopac = recallPackage mopac {};
    mpi = recallPackage mpi {};
    nwchem = recallPackage nwchem {
      blas = final.blas-ilp64;
      lapack = final.lapack-ilp64;
    };
    octopus = recallPackage octopus {};
    openmm = recallPackage openmm {
      enableCuda = cfg.useCuda;
      stdenv = final.clangStdenv;
    };
    quantum-espresso = recallPackage quantum-espresso {
      hdf5 = final.hdf5-fortran;
      inherit (final) wannier90;
    };
    pcmsolver = recallPackage pcmsolver {};
    scalapack = recallPackage scalapack {};
    siesta = recallPackage siesta {};
    siesta-mpi = recallPackage siesta-mpi {};
    sirius = recallPackage sirius {};
    spglib = recallPackage spglib {};

    fftwSinglePrec = self.fftw.override { precision = "single"; };

    gromacs = recallPackage gromacs {
      cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
      fftw = self.fftwSinglePrec;
    };

    gromacsMpi = recallPackage gromacsMpi {
      cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
      fftw = self.fftwSinglePrec;
    };

    gromacsDouble = recallPackage gromacsDouble {
      cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
      enableCuda = false; # CUDA + double prec. not supported
    };

    gromacsDoubleMpi = recallPackage gromacsDoubleMpi {
      cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
      enableCuda = false; # CUDA + double prec. not supported
    };

    libxsmm = (recallPackage libxsmm {}).overrideAttrs ( x: {
      makeFlags = x.makeFlags or [] ++ [ "OPT=3" ]
        ++ lib.optional hp.avx2Support ["AVX=2" ];
    });

    ucx = recallPackage ucx {};
    ucc = recallPackage ucc {};
    wannier90 = recallPackage wannier90 {};
    wxmacmolplt = recallPackage wxmacmolplt {};

    hostPlatform = hp;
  };

in set
