{ stdenv, pkgs, fetchFromGitHub, python, gfortran, openblasCompat
, fftw, libint, libxc, mpi, gsl, scalapack, openssh, makeWrapper
} :

let
  version = "6.1.0";

  cp2kVersion = "psmp";

  config = pkgs.writeText "cp2kConfig" ''
    CC         = gcc
    CPP        =
    FC         = mpif90
    LD         = mpif90
    AR         = ar -r
    DFLAGS     = -D__FFTW3 -D__LIBXC -D__parallel -D__SCALAPACK \
                 -D__MPI_VERSION=3 -D__F2008 \
                 -D__LIBINT_MAX_AM=7 -D__LIBDERIV_MAX_AM1=6 -D__MAX_CONTR=4

    FCFLAGS    = $(DFLAGS) -O2 -ffast-math -ffree-form -ffree-line-length-none \
                 -ftree-vectorize -funroll-loops -mtune=native -std=f2008 \
                 -I${libxc}/include
    LIBS       = -lfftw3 -lfftw3_threads -lscalapack -lopenblas \
                 -lxcf03 -lxc -lint2
  '';

in stdenv.mkDerivation rec {
  name = "cp2k-${version}";

  src = fetchFromGitHub {
    owner = "cp2k";
    repo = "cp2k";
    rev = "v${version}";
    sha256 = "1c2f1pqa2basv034dds1lnpswxczhk20kx3vh5w84skmc34v6921";
  };

  nativeBuildInputs = [ python openssh makeWrapper ];
  buildInputs = [ gfortran fftw libint libxc openblasCompat mpi scalapack ];

  makeFlags = [
    "ARCH=Linux-x86-64-gfortran"
    "VERSION=${cp2kVersion}"
  ];

  doCheck = false; # to big

  enableParallelBuilding = true;

  postPatch = ''
    cp ${config} arch/Linux-x86-64-gfortran.${cp2kVersion}
    patchShebangs tools
  '';

  preBuild = ''
    cd makefiles
  '';

  checkPhase = ''
    make ${toString makeFlags} test
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/cp2k

    cd ..
    cp exe/Linux-x86-64-gfortran/* $out/bin
    makeWrapper $out/bin/cp2k.${cp2kVersion} $out/bin/cp2k --set CP2K_DATA_DIR $out/share/cp2k

    cp -r data/* $out/share/cp2k

    ln -s ${mpi}/bin/mpirun $out/bin/mpirun
    ln -s ${mpi}/bin/mpiexec $out/bin/mpiexec

  '';

  meta = with stdenv.lib; {
    description = "Quantum chemistry and solid state physics program";
    homepage = https://www.cp2k.org;
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}

