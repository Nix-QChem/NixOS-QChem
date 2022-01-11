{ buildPythonPackage, lib, fetchFromGitHub, cmake, clang, gfortran, fftwSinglePrec
, doxygen, ocl-icd, opencl-headers, swig, python, cython, numpy
, cudatoolkit, enableCuda ? false
} :

buildPythonPackage rec {
  pname = "openmm";
  version = "7.7.0";

  src = fetchFromGitHub {
    owner = "openmm";
    repo = pname;
    rev = version;
    hash = "sha256-2PYUGTMVQ5qVDeeABrwR45U3JIgo2xMXKlD6da7y3Dw=";
  };

  nativeBuildInputs = [
    cmake
    gfortran
    swig
    cython
    doxygen
  ];

  buildInputs = [
    fftwSinglePrec
    ocl-icd
    opencl-headers
  ] ++ lib.optional enableCuda cudatoolkit
  ;

  propagatedBuildInputs = [
    python
    numpy
  ];

  dontUseSetuptoolsBuild = true;
  dontUsePipInstall = true;
  dontUseSetuptoolsCheck = true;

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
    "-DBUILD_TESTING=ON"
    "-DOPENMM_BUILD_AMOEBA_PLUGIN=ON"
    "-DOPENMM_BUILD_CPU_LIB=ON"
    "-DOPENMM_BUILD_C_AND_FORTRAN_WRAPPERS=ON"
    "-DOPENMM_BUILD_DRUDE_PLUGIN=ON"
    "-DOPENMM_BUILD_PME_PLUGIN=ON"
    "-DOPENMM_BUILD_PYTHON_WRAPPERS=ON"
    "-DOPENMM_BUILD_RPMD_PLUGIN=ON"
    "-DOPENMM_BUILD_SHARED_LIB=ON"
    "-DOPENMM_BUILD_AMOEBA_OPENCL_LIB=ON"
    "-DOPENMM_BUILD_OPENCL_LIB=ON"
    "-DOPENMM_BUILD_DRUDE_OPENCL_LIB=ON"
    "-DOPENMM_BUILD_RPMD_OPENCL_LIB=ON"
  ] ++ lib.optionals enableCuda [
    "-DCUDA_SDK_ROOT_DIR=${cudatoolkit}"
    "-DOPENMM_BUILD_AMOEBA_CUDA_LIB=ON"
    "-DOPENMM_BUILD_CUDA_LIB=ON"
    "-DOPENMM_BUILD_DRUDE_CUDA_LIB=ON"
    "-DOPENMM_BUILD_RPMD_CUDA_LIB=ON"
    "-DCMAKE_LIBRARY_PATH=${cudatoolkit}/lib64/stubs"
  ];

  enableParallelBuilding = true;

  doCheck = true;

  # "make PythonInstall" wants to install into the store-path of the python executable.
  # Therefore, execute setup.py manually and choose the appropriate prefix.
  postInstall = ''
    cd python
    export OPENMM_INCLUDE_PATH=$out/include
    export OPENMM_LIB_PATH=$out/lib
    python setup.py build && python setup.py install --prefix=$out
  '';

  meta = with lib; {
    description = "Toolkit for molecular simulation using high performance GPU code";
    homepage = "https://openmm.org/";
    license = with licenses; [ gpl3Plus lgpl3Plus mit ];
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
