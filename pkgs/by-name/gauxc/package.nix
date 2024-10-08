{ stdenv
, lib
, fetchFromGitHub
, symlinkJoin
, cmake
, mpi
, blas
, gau2grid
, integratorxx
, exchcxx
, hdf5-mpi
, highfive-mpi
, eigen
, catch2
, cereal
, mpiCheckPhaseHook
, pkg-config
, cfg
, autoAddDriverRunpath
, enableCuda ? cfg.useCuda
  # CUDA compute capability. 60 is the minimum required by GauXC. Set according to GPU.
, cudaArchitecture ? "60"
, cudaPackages
, magma-cuda
, enableHip ? false
, rocmPackages
, magma-hip
}:

assert enableCuda -> !enableHip;

let
  linalgCmake = fetchFromGitHub {
    owner = "wavefunction91";
    repo = "linalg-cmake-modules";
    rev = "28ceaa9738f14935aa544289fa2fe4c4cc955d0e";
    hash = "sha256-EGPubUYlZjgJRnUdtgCG+aKcmkpQk1m9N3VVYMgIwic=";
  };

  rocmMerged = symlinkJoin {
    name = "rocm-merged";

    paths = with rocmPackages; [
      clr
      rocm-comgr
      rocm-device-libs
      rocm-runtime
      rocprim
      hipsparse
      hipblas
      hipcub
      clr.icd
    ];
  };

in
stdenv.mkDerivation rec {
  pname = "GauXC";
  version = "unstable-2024-09-30";

  # Upstream version is from wavefunction91, but has HIP bugs not fixed yet
  src = fetchFromGitHub {
    owner = "ryanstocks00";
    repo = pname;
    rev = "ecf6eacc411a4cfe09e6f8e5b3b2855264e0ffb7";
    hash = "sha256-uqVkQfn5UWxJq3DUnxgkoIfEflU/kQXyvJZlmeQk+pM=";
  };

  patches = [
    # Uses a a local clone of the linalg-cmake-modules repository instead of fetching it.
    # Substitute @LINALG_CMAKE_MODULES_DIR@ with the path to the prefetched linalg-cmake-modules repository.
    ./Linalg.patch

    # Allows usage of a installed HighFive version instead of fetching it
    ./HighFive.patch

    # Removes the hardcoded forced static linking
    ./DynamicLinking.patch

    # Forces the MPI tests to strictly run after the serial tests. Otherwise,
    # both will occasionally try to write to the same file at the same time.
    ./TestSerial.patch

    # Upstreams config-cmake has a syntax error, so that GauXC cannot be found
    # as dependency by other projects. This patch fixes the syntax error.
    ./CmakeConfig.patch
  ];

  postPatch = ''
    substituteInPlace cmake/gauxc-linalg-modules.cmake src/CMakeLists.txt \
      --subst-var-by "LINALG_CMAKE_MODULES_DIR" "${linalgCmake}"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ] ++ lib.optional (enableCuda || enableHip) autoAddDriverRunpath;

  buildInputs = [
    hdf5-mpi
  ] ++ lib.optionals enableCuda (with cudaPackages; [
    libcublas
    cuda_nvcc
    cuda_cudart
    cuda_cccl
    libcusparse
    magma-cuda
  ]) ++ lib.optionals enableHip [
    rocmMerged
    magma-hip
  ];

  propagatedBuildInputs = [
    highfive-mpi
    gau2grid
    integratorxx
    exchcxx
    blas
    mpi
  ];

  # Interestingly the ROCM_PATH must be set both as environment variable and
  # passed to CMake to make HIP work. One is not enough.
  preConfigure = lib.optionalString enableHip ''
    export ROCM_PATH=${rocmMerged}
  '';

  cmakeFlags = with lib.strings; [
    (cmakeBool "GAUXC_ENABLE_MPI" true)
    (cmakeBool "GAUXC_ENABLE_OPENMP" true)
    (cmakeBool "GAUXC_ENABLE_CUDA" enableCuda)
    (cmakeBool "GAUXC_ENABLE_HIP" enableHip)
  ] ++ lib.optionals enableCuda [
    (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaArchitecture)
  ] ++ lib.optionals enableHip [
    (cmakeFeature "ROCM_PATH" (builtins.toString rocmMerged))
  ];


  # Checks with accelerators don't work in the sandbox
  doCheck = !enableCuda && !enableHip;

  nativeCheckInputs = [ mpiCheckPhaseHook ];

  checkInputs = [
    eigen
    catch2
    cereal
  ];

  meta = with lib; {
    description = "Evaluation of quantities related to the exchange-correlation energy (e.g. potential, etc) in the Gaussian basis set discretization of Kohn-Sham density function theory";
    homepage = "https://github.com/wavefunction91/GauXC";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
