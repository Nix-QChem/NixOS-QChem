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
    cp2k = recallPackage cp2k {};
    fftw = recallPackage fftw {};
    dkh = recallPackage dkh {};
    elpa = recallPackage elpa {};
    ergoscf = recallPackage ergoscf {};
    harminv = recallPackage harminv {};
    inherit (final) hdf5;
    hpl = recallPackage hpl {};
    hpcg = recallPackage hpcg {};
    i-pi = recallPackage i-pi {};
    gsl = recallPackage gsl {};
    gpaw = python3.pkgs.toPythonApplication (recallPackage python3.pkgs.gpaw {});
    libint = recallPackage libint {};
    libvori = recallPackage libvori {};
    libxc = recallPackage libxc {};
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
    quantum-espresso = recallPackage quantum-espresso {};
    quantum-espresso-mpi = recallPackage quantum-espresso-mpi {};
    pcmsolver = recallPackage pcmsolver {};
    scalapack = recallPackage scalapack {};
    siesta = recallPackage siesta {};
    siesta-mpi = recallPackage siesta-mpi {};
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
    };

    gromacsDoubleMpi = recallPackage gromacsDoubleMpi {
      cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
    };

    gromacsCudaMpi = recallPackage gromacsCudaMpi {
      fftw = self.fftwSinglePrec;
      cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
    };

    libxsmm = (recallPackage libxsmm {}).overrideAttrs ( x: {
      makeFlags = x.makeFlags or [] ++ [ "OPT=3" ]
        ++ lib.optional hp.avx2Support ["AVX=2" ];
    });

    ucc = recallPackage ucc {};
    wxmacmolplt = recallPackage wxmacmolplt {};

    hostPlatform = hp;
  };

in set
