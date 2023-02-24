{ buildPythonPackage
, lib
, gfortran
, fetchFromGitHub
, cmake
, blas
, lapack
, mpi
, scalapack
, test-drive
, mctc-lib
, mstore
, toml-f
, tblite
, mpifx
, scalapackfx
, simple-dftd3
, multicharge
, dftd4
, numpy
}:

assert !blas.isILP64 && !lapack.isILP64;

buildPythonPackage rec {
  pname = "dftbplus";
  version = "22.2";

  src = fetchFromGitHub {
    owner = "dftbplus";
    repo = pname;
    rev = version;
    hash = "sha256-bADKCee5vBH3aIhuo0Ce/GrZ//nd8j4AcWDSWYoLRY4=";
  };

  postPatch = ''
    patchShebangs .

    substituteInPlace tools/dptools/CMakeLists.txt \
      --replace '$DESTDIR/' ""
  '';

  nativeBuildInputs = [
    gfortran
    cmake
  ];

  buildInputs = [
    blas
    lapack
    scalapack
    test-drive
    mctc-lib
    mstore
    toml-f
    tblite
    mpifx
    scalapackfx
    simple-dftd3
    multicharge
    dftd4
  ];

  propagatedBuildInputs = [ numpy ];

  format = "other";

  cmakeFlags = [
    "-DWITH_API=ON"
    "-DWITH_OMP=ON"
    "-DWITH_MPI=ON"
    "-DWITH_TBLITE=ON"
    "-DWITH=SDFTD3=ON"
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
  };
}
