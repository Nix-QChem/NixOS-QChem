{ stdenv, lib, fetchgit, gfortran, cmake, makeWrapper
, which, openssh, blas, lapack, mpi, boost, exatensor
, python3, hdf5
} :

# A 64bit int build would be possible without MPI and Exatensor,
# although I couldn't figure out how exactly ...
assert
  lib.asserts.assertMsg
  (!blas.isILP64)
  "A 32 bit integer implementation of BLAS is required.";

stdenv.mkDerivation rec {
  pname = "dirac";
  version = "22.0";

  nativeBuildInputs = [
    which
    gfortran
    cmake
    makeWrapper
    openssh
  ];

  buildInputs = [
    blas
    lapack
    boost
    exatensor
    hdf5
  ];

  propagatedBuildInputs = [ mpi python3 ];

  # Dirac requires a multitude of submodules, which all need to be present.
  src = fetchgit {
    url = "https://gitlab.com/dirac/dirac/";
    rev = "37b755410d9fdcd9b5e7bba6e43ceb7d5c7b9dae"; # v22.0, fetchgit does not handle the tag on gitlab correctly
    hash = "sha256-sRlP5WlIWm/4oWwXArQk6DWMHU+JJuG1JkPoVtwnM/k=";
    deepClone = true;
    fetchSubmodules = true;
  };


  patches = [
    # Exatensor is downloaded and built on the fly by CMake. We instead link to the Exatensor
    # from the package set to avoid download an build.
    ./exatensor-cmake.patch

    # Pass -fallow-argument-mismatch also to the pelib build. The Cmake build system will
    # override the environment variable already set.
    ./pelib-fortran.patch
  ];

  postPatch = ''
    substituteInPlace ./cmake/custom/exatensor.cmake \
    --subst-var-by exatensor ${exatensor}

    patchShebangs .
  '';

  preConfigure = ''
    export FC=mpif90
    export CC=mpicc
    export CXX=mpicxx
    export FCFLAGS=-fallow-argument-mismatch
    export FFLAGS=-fallow-argument-mismatch
    export MATHROOT=${blas}

    cmakeFlagsArray+=(
      "-DENABLE_MPI=ON"
      "-DMATH_LIB_SEARCH_ORDER=SYSTEM_NATIVE"
      "-DBLAS_LANG=Fortran"
      "-DLAPACK_LANG=Fortran"
      "-DENABLE_OPENMP=ON"
      "-DENABLE_PROFILING=OFF"
      "-DENABLE_64BIT_INTEGERS=OFF"
      "-DENABLE_EXATENSOR=ON"
      "-DCMAKE_BUILD_TYPE=release"
      "-DENABLE_PCMSOLVER=OFF"
      "-DENABLE_BLAS=ON"
      "-DENABLE_LAPACK=ON"
      "-DEXPLICIT_LIBS=-lblas -llapack"
      "-DMKL_FLAG=off"
    )
  '';

  hardeningDisable = [ "format" ];
  doInstallCheck = true;
  enableParallelBuilding = true;

  /*
  Make the MPI stuff available to the DIRAC script by hard-coding the MPI path.
  Moving pam-dirac to pam to conform with the DIRAC manual. Usually there is a
  weird hack in the install.cmake to install pam into the bin folder.

  The pam script is just a Python script that sets a ton of ENV variables.
  */
  postFixup = ''
    mv $out/bin/pam-dirac $out/bin/pam

    substituteInPlace $out/bin/pam \
      --replace "find_executable('mpirun')" "'${mpi}/bin/mpirun'"
  '';

  # This is a small initial calculation to see whether everything works just fine.
  # http://diracprogram.org/doc/release-21/tutorials/getting_started.html
  installCheckPhase = ''
    cat > methanol.xyz << EOF
      6
      my first DIRAC calculation # anything can be in this line
      C       0.000000000000       0.138569980000       0.355570700000
      O       0.000000000000       0.187935770000      -1.074466460000
      H       0.882876920000      -0.383123830000       0.697839450000
      H      -0.882876940000      -0.383123830000       0.697839450000
      H       0.000000000000       1.145042790000       0.750208830000
      H       0.000000000000      -0.705300580000      -1.426986340000
    EOF

    cat > hf.inp <<-EOF
    **DIRAC
    .WAVE FUNCTION
    **WAVE FUNCTION
    .SCF
    **MOLECULE
    *BASIS
    .DEFAULT
    cc-pVDZ
    *END OF INPUT
    EOF

    $out/bin/pam --mpi=2 --mol=$(pwd)/methanol.xyz --inp=$(pwd)/hf.inp --scratch=$(pwd)
  '';

  passthru = { inherit mpi; };

  meta = with lib; {
    description = "The DIRAC program computes molecular properties using relativistic quantum chemical methods.";
    license = licenses.lgpl2;
    homepage = "https://diracprogram.org/";
    platforms = platforms.linux;
  };
}
