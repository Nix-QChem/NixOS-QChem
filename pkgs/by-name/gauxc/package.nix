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
    rev = "9d2c273a671d6811e9fd432f6a4fa3d915b144b8";
    hash = "sha256-/OfP869HawRLCNLC5QMP3YgdrkgCkPGcv/YFwDhbPso=";
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
  pname = "gauxc";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "wavefunction91";
    repo = "GauXC";
    tag = "v${version}";
    hash = "sha256-ZdgwxZ/V/CZZaOSSDKo3XLPC+7yckozEGCPW8jD6ES8=";
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

    # GauXC wants to build cereal with special flags in place. This patch allows
    # using cereal.src and avoids the otherwise required network access
    ./cereal.patch
  ];

  postPatch = ''
    substituteInPlace cmake/gauxc-linalg-modules.cmake src/CMakeLists.txt \
      --subst-var-by "LINALG_CMAKE_MODULES_DIR" "${linalgCmake}"

    substituteInPlace cmake/BuildFindCereal.cmake \
      --subst-var-by "cereal" "${cereal.src}"
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
  ];

  meta = with lib; {
    description = "Evaluation of quantities related to the exchange-correlation energy (e.g. potential, etc) in the Gaussian basis set discretization of Kohn-Sham density function theory";
    homepage = "https://github.com/wavefunction91/GauXC";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
