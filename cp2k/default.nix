{ stdenv, pkgs, fetchFromGitHub, python, gfortran, openblasCompat
, fftw, libint1, libxc, mpi, gsl, scalapack, openssh, makeWrapper
, libxsmm
} :

let
  version = "6.1.0";

  cp2kVersion = "psmp";
  arch = "Linux-x86-64-gfortran";

  config = pkgs.writeText "cp2kConfig" ''
    CC         = gcc
    CPP        =
    FC         = mpif90
    LD         = mpif90
    AR         = ar -r
    DFLAGS     = -D__FFTW3 -D__LIBXC -D__LIBINT -D__parallel -D__SCALAPACK \
                 -D__MPI_VERSION=3 -D__F2008 -D__LIBXSMM \
                 -D__LIBINT_MAX_AM=7 -D__LIBDERIV_MAX_AM1=6 -D__MAX_CONTR=4

    FCFLAGS    = $(DFLAGS) -O2 -ffree-form -ffree-line-length-none \
                 -ftree-vectorize -funroll-loops -msse2 -mavx -mavx2 -std=f2008 \
                 -I${libxc}/include -I${libxsmm}/include \
                 -fopenmp -ftree-vectorize -funroll-loops
    LIBS       = -lfftw3 -lfftw3_threads -lfftw3_omp -lscalapack -lopenblas \
                 -lxcf03 -lxc -lxsmmf -lxsmm \
                 ${libint1}/lib/libderiv.a ${libint1}/lib/libint.a \
                 -fopenmp
  '';

in stdenv.mkDerivation rec {
  name = "cp2k-${version}";

  src = fetchFromGitHub {
    owner = "cp2k";
    repo = "cp2k";
    rev = "v${version}";
    sha256 = "1c2f1pqa2basv034dds1lnpswxczhk20kx3vh5w84skmc34v6921";
  };

  patches = [ ./openmpi4.patch ];

  nativeBuildInputs = [ python openssh makeWrapper ];
  buildInputs = [ gfortran fftw gsl libint1 libxc libxsmm openblasCompat mpi scalapack ];

  makeFlags = [
    "ARCH=${arch}"
    "VERSION=${cp2kVersion}"
  ];

  doCheck = true;

  enableParallelBuilding = true;

  postPatch = ''
    cp ${config} arch/${arch}.${cp2kVersion}
    patchShebangs tools
  '';

  preBuild = ''
    cd makefiles
  '';

  postBuild = ''
    cd ..
  '';

  checkPhase = ''
    export OMP_NUM_THREADS=1
    export OMPI_MCA_rmaps_base_oversubscribe=1
    export CP2K_DATA_DIR=data

    for i in libcp2k_unittest dbcsr_test_csr_conversions dbcsr_unittest dbcsr_tensor_unittest; do
      mpirun -np 2 exe/${arch}/$i.${cp2kVersion}
    done
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/cp2k

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

