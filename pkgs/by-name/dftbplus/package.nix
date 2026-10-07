{ stdenv
, lib
, gfortran
, fetchFromGitHub
, cmake
, python3
, pkg-config
, blas
, lapack
, plumed
, mpi
, mpiCheckPhaseHook
, enableMpi ? false
, scalapack
, config
, rocmSupport ? config.rocmSupport
, rocmPackages
, magma
}:

assert !blas.isILP64 && !lapack.isILP64;

stdenv.mkDerivation (finalAttrs: {
  pname = "dftbplus";
  version = "25.1";

  src = fetchFromGitHub {
    owner = "dftbplus";
    repo = finalAttrs.pname;
    tag = finalAttrs.version;
    hash = "sha256-9EcHYZuGYvWMoZA6NXmnR8NSgjmRbT0NZ2eaKQYe6b0=";
    fetchSubmodules = true;
  };

  postPatch = ''
    patchShebangs .
  '';

  patches = [
    # GCC 16 gfortran respects the module-level 'private' for bind(C) procedures,
    # hiding the C API symbols from the shared library. Make them public.
    ./gcc16-capi-visibility.patch
  ];

  nativeBuildInputs = [
    gfortran
    cmake
    pkg-config
    python3
  ];

  buildInputs = [
    blas
    lapack
    plumed
  ] ++ lib.optional enableMpi scalapack
  ++ lib.optionals rocmSupport (with rocmPackages; [
    magma
    hip-common
    clr
    hipblas
    hipsparse
  ]);

  propagatedBuildInputs = lib.optional enableMpi mpi;

  propagatedUserEnvPkgs = lib.optional enableMpi (lib.getBin mpi);

  passthru = lib.attrsets.optionalAttrs enableMpi { inherit mpi; };

  format = "other";

  cmakeFlags = [
    "-DWITH_API=ON"
    "-DWITH_OMP=ON"
    (lib.strings.cmakeBool "WITH_MPI" enableMpi)
    (lib.strings.cmakeBool "WITH_GPU" rocmSupport)
    "-DWITH_PYTHON=ON"
    "-DWITH_PLUMED=ON"
    "-DWITH_TBLITE=OFF"
    "-DWITH_SDFTD3=OFF"
    "-DENABLE_DYNAMIC_LOADING=ON"
    "-DBUILD_SHARED_LIBS=ON"
  ] ++ lib.optionals enableMpi [
    "-DCMAKE_Fortran_COMPILER=${lib.getDev mpi}/bin/mpif90"
    "-DCMAKE_C_COMPILER=${lib.getDev mpi}/bin/mpicc"
    "-DSCALAPACK_LIBRARY=${scalapack}/lib/libscalapack.so"
  ];

  meta = with lib; {
    description = "DFTB+ general package for performing fast atomistic simulations";
    homepage = "https://github.com/dftbplus/dftbplus";
    license = with licenses; [ gpl3Plus lgpl3Plus ];
    mainProgram = "dftb+";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
})
