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
    arpack-mpi = recallPackage arpack {
      inherit (self) mpi;
      useMpi = true;
    };
    boost-mpi = recallPackage boost {
      useMpi = true;
      inherit (self) mpi;
    };

    cp2k = recallPackage cp2k {
      libxc = pkgs.libxc_7;
      inherit (final)
        mpi
        fftw
        dbcsr
        dftd4
        simple-dftd3
        sirius
        multicharge
        libxsmm
        spglib
        scalapack
      ;
    };

    dbscr = recallPackage dbcsr {};
    fftw = recallPackage fftw {};
    fftwMpi = recallPackage fftwMpi {
      inherit (final) mpi;
    };
    dkh = recallPackage dkh {};
    dftd4 = recallPackage dftd4 {};
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
    libvdwxc = recallPackage libvdwxc {
      inherit (final) mpi fftwMpi;
    };
    libxc = recallPackage libxc {};
    libxc_7 = recallPackage libxc_7 {};
    mctc-lib = recallPackage mctc-lib {};
    mpb = recallPackage mpb {};
    meep = python3.pkgs.toPythonApplication (recallPackage python3.pkgs.meep {});
    mkl = recallPackage mkl {};
    molden = recallPackage molden {};
    mopac = recallPackage mopac {};
    mpi = recallPackage mpi {};
    multicharge = recallPackage multicharge {};
    nwchem = recallPackage nwchem {
      inherit (self) mpi;
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
    siesta-mpi = recallPackage siesta-mpi {
      inherit (final) scalapack mpi;
    };
    simple-dftd3 = recallPackage simple-dftd3 {};
    sirius = recallPackage sirius {
      inherit (final) scalapack mpi;
    };
    spglib = recallPackage spglib {};

    # tblite is broken with meson
    # tblite = recallPackage tblite {};
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
