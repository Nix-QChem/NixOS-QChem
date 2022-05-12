{ stdenv, lib, fetchFromGitLab, blas, mpi, cudaPackages, which } :

let
  version = "2022-05-07";

in stdenv.mkDerivation rec {
  pname = "exatensor";
  inherit version;

  src = fetchFromGitLab {
    owner = "DmitryLyakh";
    repo = "ExaTENSOR";
    rev = "7a75a73bc6dbfa3ff4b107231514d8f3d26e6338";
    hash = "sha256-nczcRWT/mh9yGM5qON7Zgqw/gpI1Jx7SSMlfublEgAg=";
  };

  nativeBuildInputs = [
    cudaPackages.cuda_nvcc
    which
  ];

  buildInputs = [
    blas.passthru.provider 
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvtx
    cudaPackages.libcublas
  ];

  preConfigure = 
    let
      MPILIB = if (mpi.pname == "openmpi") then "OPENMPI"
        else if (mpi.pname == "mpich") then "MPICH"
        else if (mpi.pname == "mvapich") then "MPICH"
        else throw "Only openmpi, mpich and mvapich supported by ${pname}.";
      BLASLIB =
        if (blas.passthru.implementation == "openblas") then "OPENBLAS"
          else if (blas.passthru.implementation == "mkl") then "MKL"
          else throw "Only MKL and OPENBLAS supported by ${pname}.";
    in ''
      export CUDA_HOST_COMPILER=$(which g++)
      export MPILIB=${MPILIB}
      export PATH_OPENMPI=${mpi}
      export PATH_MPICH=${mpi}
      export BLASLIB=${BLASLIB}
      export PATH_BLAS_OPENBLAS=${blas.passthru.provider}
      export PATH_BLAS_MKL=${blas.passthru.provider};
      export PATH_BLAS_MKL_DEP="${blas.passthru.provider}/lib";
      export PATH_BLAS_MKL_INC="${blas.passthru.provider}/include";
    '';

  enableParalleBuilding = true;
  hardeningDisable = [ "format" ];
  
  installPhase = ''
    mkdir -p $out/lib $out/bin $out/include
    cp -r ./bin/* $out/bin
    cp -r ./lib/* $out/lib
    cp -r ./include/* $out/include
  '';


  meta = with lib; {
    description = "ExaTENSOR is a basic numerical tensor algebra library for distributed HPC systems equipped with multicore CPU and NVIDIA or AMD GPU.";
    homepage = "https://gitlab.com/DmitryLyakh/ExaTensor";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
  };
}

