{ stdenv
, lib
, fetchFromGitHub
, cmake
, gfortran
, blas
, lapack
, scalapack
, fftwMpi
, mpi
}:

stdenv.mkDerivation rec {
  pname = "salmon";
  version = "2.2.1";

  src = fetchFromGitHub {
    owner = "SALMON-TDDFT";
    repo = "SALMON2";
    rev = "v.${version}";
    hash = "sha256-xE/2PCLkdUmSOUSbCD9SaqB09U04x8s8leh43g+rRgw=";
  };

  patches = [
    ./cpp.patch
  ];

  nativeBuildInputs = [
    gfortran
    cmake
  ];

  buildInputs = [
    blas
    lapack
    scalapack
    fftwMpi
    gfortran.cc
  ];

  propagatedBuildInputs = [ mpi ];
  propagatedUserEnvPkgs = [ mpi ];

  preConfigure = ''
    cmakeFlagsArray+=(
      "-DCMAKE_Fortran_FLAGS=-fallow-argument-mismatch -I${lib.getDev fftwMpi}/include"
      "-DCMAKE_EXE_LINKER_FLAGS=-lfftw3_mpi -lfftw3 -lgomp -lmpi -lblas -llapack -lscalapack -lgfortran"
      "-DUSE_MPI=ON"
      "-DUSE_FFTW=ON"
      "-DUSE_SCALAPACK=ON"
      "-DScaLAPACK_FOUND=ON"
      "-DScaLAPACK_LIBRARIES=-lscalapack"
    )
  '';

  passthru = { inherit mpi; };

  meta = with lib; {
    description = "Scalable Ab-initio Light-Matter simulator for Optics and Nanoscience";
    homepage = "https://github.com/SALMON-TDDFT/SALMON2";
    license = with licenses; [ asl20 ];
    maintainers = [ maintainers.sheepforce ];
    platforms = platforms.linux;
  };
}
