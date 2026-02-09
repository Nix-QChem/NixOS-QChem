{ lib, stdenv, fetchFromGitHub, cmake, openssh, mpiCheckPhaseHook
, gfortran, mpi, blas, lapack
} :

assert blas.isILP64 == lapack.isILP64;

stdenv.mkDerivation rec {
  pname = "amd-scalapack";
  version = "5.2";

  src = fetchFromGitHub {
    owner = "amd";
    repo = "aocl-scalapack";
    rev = "${version}";
    sha256 = "sha256-vtN0e1Kzehb8zBX/T5eOvA4UMUTm4XuUbuBu74iECg0=";
  };

  passthru.isILP64 = blas.isILP64;

  nativeBuildInputs = [ cmake gfortran ];
  buildInputs = [ mpi blas lapack ];

  doCheck = true;

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_STATIC_LIBS=OFF"
    "-DUSE_OPTIMIZED_LAPACK_BLAS=ON"
    "-DSCALAPACK_BUILD_TESTS=ON"
  ] ++ lib.optional blas.isILP64 "-DENABLE_ILP64=ON";

  env.NIX_CFLAGS_COMPILE = "-Wno-incompatible-pointer-types -std=gnu17";

  preConfigure = ''
    cmakeFlagsArray+=( "-DCMAKE_Fortran_FLAGS=-fallow-argument-mismatch" )
  '';

  # Increase individual test timeout from 1500s to 10000s because hydra's builds
  # sometimes fail due to this
  checkFlagsArray = [ "ARGS=--timeout 10000" ];

  nativeCheckInputs = [
    openssh
    mpiCheckPhaseHook
  ];

  preCheck = ''
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}`pwd`/lib
  '';

  meta = with lib; {
    homepage = "https://developer.amd.com/amd-aocl/scalapack/";
    description = "Linear algebra routines for parallel distributed memory machines optimized for AMD processors";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ markuskowa ];
  };

}
