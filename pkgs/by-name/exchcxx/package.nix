{ stdenv
, lib
, fetchFromGitHub
, symlinkJoin
, cmake
, libxc
, cfg
, enableCuda ? cfg.useCuda
, cudaPackages
, autoAddDriverRunpath
, enableHip ? false
, rocmPackages
}:

assert enableCuda -> !enableHip;

let
  rocmMerged = symlinkJoin {
    name = "rocm-merged";

    paths = with rocmPackages; [
      clr
      rocm-comgr
      rocm-device-libs
      rocm-runtime
      clr.icd
    ];
  };

in
stdenv.mkDerivation rec {
  pname = "exchcxx";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "wavefunction91";
    repo = "ExchCXX";
    tag = "v${version}";
    hash = "sha256-Ar83mWSmaJVrG8b7NXaLpC7a5Mka6+CnXg2RRa8k+J0=";
  };

  nativeBuildInputs = [
    cmake
  ] ++ lib.optional (enableCuda || enableHip) autoAddDriverRunpath;

  buildInputs = lib.optionals enableCuda
    (with cudaPackages; [
      cudatoolkit
      cuda_cudart
    ]) ++ lib.optionals enableHip [
      rocmMerged
    ];

  # Yes, really. This needs to be propagated. Otherwise downstream CMake will
  # complain when trying to find ExchCXX.
  propagatedBuildInputs = [
    libxc
  ];

  # Required to make the HIP compiler work in this CMake setup
  preConfigure = lib.strings.optionalString enableHip ''
    export ROCM_PATH=${rocmMerged}
  '';

  cmakeFlags = with lib.strings; [
    (cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
    (cmakeBool "EXCHCXX_ENABLE_CUDA" enableCuda)
    (cmakeBool "EXCHCXX_ENABLE_HIP" enableHip)
  ];

  # Checks with accelerators don't work in the sandbox
  doCheck = !enableCuda && !enableHip;

  meta = with lib; {
    description = "Exchange correlation library for density functional theory calculations";
    homepage = "https://github.com/wavefunction91/ExchCXX";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
