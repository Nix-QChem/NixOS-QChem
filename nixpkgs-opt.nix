cfg: final: prev: self: optStdenv:

#
# Package set with upstream libraries
# and optimizations of upstream packages
#

let
  hp = optStdenv.hostPlatform;
  inherit (final) lib;

  optSet = lib.fix (self:
    let
      recallPackage = x: inputs: x.override ((builtins.intersectAttrs x.override.__functionArgs self) // inputs);
    in {
      stdenv = optStdenv;
      inherit (self.stdenv) hostPlatform;

      avogadro2 = recallPackage final.avogadro2 {};
      arpack = recallPackage final.arpack {};
      arpack-mpi = recallPackage final.arpack-mpi {};
      boost-mpi = recallPackage final.boost {
        useMpi = true;
      };

      cp2k = recallPackage final.cp2k {
        libxc = self.libxc_7;
      };

      dbcsr = recallPackage final.dbcsr {};
      fftw = recallPackage final.fftw {};
      fftwMpi = recallPackage final.fftwMpi {};
      fftwSinglePrec = recallPackage final.fftwSinglePrec {};
      dkh = recallPackage final.dkh {};
      dftd4 = recallPackage final.dftd4 {};
      # Currently broken upstream. Put back after next upgrade
      elpa = recallPackage final.elpa {};
      ergoscf = recallPackage final.ergoscf {};
      harminv = recallPackage final.harminv {};
      hdf5 = recallPackage final.hdf5 {};
      hpl = recallPackage final.hpl {};
      hpcg = recallPackage final.hpcg {};
      i-pi = recallPackage final.i-pi {};
      gsl = recallPackage final.gsl {};
      gpaw = final.python3.pkgs.toPythonApplication (recallPackage final.python3.pkgs.gpaw {});
      lapack-reference = recallPackage final.lapack-reference {};
      libint = recallPackage final.libint {};
      libmbd = recallPackage final.libmbd {};
      libvori = recallPackage final.libvori {};
      libvdwxc = recallPackage final.libvdwxc {};
      libxc = recallPackage final.libxc {};
      libxc_7 = recallPackage final.libxc_7 {};
      mctc-lib = recallPackage final.mctc-lib {};
      mpb = recallPackage final.mpb {};
      meep = final.python3.pkgs.toPythonApplication (recallPackage final.python3.pkgs.meep {});
      mkl = recallPackage final.mkl {};
      molbar = recallPackage final.molbar {};
      molden = recallPackage final.molden {};
      mopac = recallPackage final.mopac {};
      mpi = recallPackage final.mpi {};
      multicharge = recallPackage final.multicharge {};
      nwchem = recallPackage final.nwchem {
        blas = final.blas-ilp64;
        lapack = final.lapack-ilp64;
        scalapack = final.scalapack-ilp64;
      };
      octopus = recallPackage final.octopus {};
      openmm = recallPackage final.openmm {
        enableCuda = cfg.useCuda;
        stdenv = final.clangStdenv;
      };
      openmolcas = recallPackage final.openmolcas {};
      quantum-espresso = recallPackage final.quantum-espresso {
        hdf5 = final.hdf5-fortran;
      };
      pcmsolver = recallPackage final.pcmsolver {};
      scalapack = recallPackage final.scalapack {};
      scalapack-ilp64 = recallPackage final.scalapack-ilp64 {};
      siesta = recallPackage final.siesta {};
      siesta-mpi = recallPackage final.siesta-mpi {};
      simple-dftd3 = recallPackage final.simple-dftd3 {};
      sirius = recallPackage final.sirius {};
      spglib = recallPackage final.spglib {};
      spla = recallPackage final.spla {};
      spfft = recallPackage final.spfft {};
      tblite = recallPackage final.tblite {};

      # gromacs = recallPackage final.gromacs {};
      # gromacsMpi = recallPackage final.gromacsMpi {};
      gromacs = recallPackage final.gromacs {
        cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
        fftw = self.fftwSinglePrec;
      };

      gromacsMpi = recallPackage final.gromacsMpi {
        cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
        fftw = self.fftwSinglePrec;
      };

      gromacsDouble = recallPackage final.gromacsDouble {
        cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
        enableCuda = false; # CUDA + double prec. not supported
      };

      gromacsDoubleMpi = recallPackage final.gromacsDoubleMpi {
        cpuAcceleration = if hp.avx2Support then "AVX2_256" else null;
        enableCuda = false; # CUDA + double prec. not supported
      };

      libxsmm = (recallPackage final.libxsmm {}).overrideAttrs ( x: {
        makeFlags = x.makeFlags or [] ++ [ "OPT=3" ]
          ++ lib.optional hp.avx2Support ["AVX=2" ];
      });

      ucx = recallPackage final.ucx {};
      ucc = recallPackage final.ucc {};
      wannier90 = recallPackage final.wannier90 {};
      wxmacmolplt = recallPackage final.wxmacmolplt {};
    });

in optSet
