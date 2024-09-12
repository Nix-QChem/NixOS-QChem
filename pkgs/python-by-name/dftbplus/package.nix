{ buildPythonPackage
, lib
, gfortran
, fetchFromGitHub
, cmake
, pkg-config
, blas
, lapack
, mpi
, scalapack
, numpy
, setuptools
}:

assert !blas.isILP64 && !lapack.isILP64;

buildPythonPackage rec {
  pname = "dftbplus";
  version = "unstable-2024-08-23";

  src = fetchFromGitHub {
    owner = "dftbplus";
    repo = pname;
    rev = "3f8a8d15a577ca039950ebbdb6c120667aca5728";
    hash = "sha256-AJSDBd1BBHYvhVmJPYP7R0UmEiOeUMJlMtX8zdutJMI=";
    fetchSubmodules = true;
  };

  postPatch = ''
    patchShebangs .
  '';

  nativeBuildInputs = [
    gfortran
    cmake
    pkg-config
    setuptools
  ];

  buildInputs = [
    blas
    lapack
    scalapack
  ];

  propagatedBuildInputs = [ numpy mpi ];
  propagatedUserEnvPkgs = [ (lib.getBin mpi) ];

  passthru = { inherit mpi; };

  format = "other";

  cmakeFlags = [
    "-DWITH_API=ON"
    "-DWITH_OMP=ON"
    "-DWITH_MPI=ON"
    "-DCMAKE_Fortran_COMPILER=${lib.getDev mpi}/bin/mpif90"
    "-DCMAKE_C_COMPILER=${lib.getDev mpi}/bin/mpicc"
    "-DWITH_TBLITE=OFF"
    "-DWITH_SDFTD3=OFF"
    "-DWITH_PYTHON=ON"
    "-DENABLE_DYNAMIC_LOADING=ON"
    "-DBUILD_SHARED_LIBS=ON"
    "-DSCALAPACK_LIBRARY=${scalapack}/lib/libscalapack.so"
  ];

  meta = with lib; {
    description = "DFTB+ general package for performing fast atomistic simulations";
    homepage = "https://github.com/dftbplus/dftbplus";
    license = with licenses; [ gpl3Plus lgpl3Plus ];
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
