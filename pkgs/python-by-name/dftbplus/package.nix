{ buildPythonPackage
, lib
, pythonAtLeast
, gfortran
, fetchFromGitHub
, cmake
, pkg-config
, blas
, lapack
, mpi
, scalapack
, dftd4
, numpy
}:

assert !blas.isILP64 && !lapack.isILP64;

buildPythonPackage rec {
  pname = "dftbplus";
  version = "24.1";

  src = fetchFromGitHub {
    owner = "dftbplus";
    repo = pname;
    rev = version;
    hash = "sha256-lI0l977SYHIgPKZ9037q7IYudAck2vyI2byW0vBB680=";
    fetchSubmodules = true;
  };

  postPatch = ''
    patchShebangs .

    substituteInPlace tools/dptools/CMakeLists.txt \
      --replace-fail '$DESTDIR/' ""
  '';

  nativeBuildInputs = [
    gfortran
    cmake
    pkg-config
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
    "-DSCALAPACK_LIBRARY=${scalapack}/lib/libscalapack.so"
  ];

  pythonImportsCheck = [ "dptools" ];

  meta = with lib; {
    description = "DFTB+ general package for performing fast atomistic simulations";
    homepage = "https://github.com/dftbplus/dftbplus";
    license = with licenses; [ gpl3Plus lgpl3Plus ];
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    broken = pythonAtLeast "3.12";
  };
}
