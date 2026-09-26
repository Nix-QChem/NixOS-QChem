{ buildPythonPackage
, lib
, fetchFromGitHub
, fetchurl
, cmake
, ninja
, gfortran
, setuptools
, scikit-build-core
, numpy
, scipy
, cffi
, basis_set_exchange
, blas
, lapack
, libxc
, libecpint
, libint
, mpi
, mpi4py
, mctc-lib
, multicharge
, dftd4
, mstore
, newScope
, pytestCheckHook
, mpiCheckPhaseHook
}:

assert blas.isILP64;
assert lapack.isILP64;

let
  # libint upstream generates fortran_incldefs.h and libint2_types_f.h during
  # its CMake build (via make_defs.py / c_to_f.py) but does not install them.
  # Patch the CMakeLists.txt to also install these headers alongside the
  # Fortran module, so downstream Fortran consumers (like OpenQP) can #include them.
  libintWithFortranHeaders = libint.overrideAttrs (old: {
    # Install the Fortran interface headers that upstream generates but
    # does not install.  Also create sanitized copies of config.h and
    # libint2_params.h (strip C++ // comments and __has_* directives that
    # crash gfortran's preprocessor).
    preFixup = (old.preFixup or "") + ''
      for f in fortran_incldefs.h libint2_types_f.h; do
        if [ -f "fortran/$f" ]; then
          install -Dm644 "fortran/$f" "$out/include/fortran/$f"
        fi
      done
      mkdir -p "$out/include/fortran/libint2/util/generated"
      # Sanitize config.h and libint2_params.h for gfortran's preprocessor:
      # strip C++ // comments and replace __has_* directives (unsupported,
      # causes internal compiler error) with 0.
      sed -e 's|//.*||g' \
          -e 's|__has_cpp_attribute([^)]*)|0|g' \
          -e 's|__has_attribute([^)]*)|0|g' \
          -e 's|__has_include([^)]*)|0|g' \
          "$out/include/libint2/config.h" \
          > "$out/include/fortran/libint2/config.h"
      sed -e 's|//.*||g' \
          -e 's|__has_cpp_attribute([^)]*)|0|g' \
          -e 's|__has_attribute([^)]*)|0|g' \
          -e 's|__has_include([^)]*)|0|g' \
          "$out/include/libint2/util/generated/libint2_params.h" \
          > "$out/include/fortran/libint2/util/generated/libint2_params.h"
    '';
  });
  # Use lib.makeScope to create a consistent set of cmake-built grimme
  # libraries with ILP64 BLAS, so they can find each other via
  # find_package(CONFIG) and propagate dependencies correctly.
  # This mirrors the pattern used by CP2K in nixpkgs.
  grimmeCmake = lib.makeScope newScope (self: {
    mctc-lib = mctc-lib.override { buildType = "cmake"; };
    mstore = mstore.override {
      buildType = "cmake";
      inherit (self) mctc-lib;
    };
    multicharge = (multicharge.override {
      buildType = "cmake";
      inherit (self) mctc-lib mstore;
    }).overrideAttrs (old: {
      buildInputs = [ blas lapack ];
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DWITH_ILP64=ON"
        "-DBLAS_LIBRARIES=${lib.getLib blas}/lib/libblas.so"
        "-DLAPACK_LIBRARIES=${lib.getLib lapack}/lib/liblapack.so"
      ];
    });
    dftd4 = (dftd4.override {
      buildType = "cmake";
      inherit (self) mctc-lib mstore multicharge;
    }).overrideAttrs (old: {
      buildInputs = [ blas lapack ];
      propagatedBuildInputs = [ self.mctc-lib self.mstore self.multicharge ];
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DWITH_ILP64=ON"
        "-DBLAS_LIBRARIES=${lib.getLib blas}/lib/libblas.so"
        "-DLAPACK_LIBRARIES=${lib.getLib lapack}/lib/liblapack.so"
      ];
    });
  });

  tagarrayTarball = fetchurl {
    url = "https://github.com/Open-Quantum-Platform/tagarray/archive/refs/tags/v1.0.0.tar.gz";
    hash = "sha256-WQiWvNqtykw0ZkdNNe/wbtQJDELTej+N3aDe+DgzxsU=";
  };

in
buildPythonPackage rec {
  pname = "openqp";
  version = "1.3.1";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "Open-Quantum-Platform";
    repo = "openqp";
    rev = "v${version}";
    hash = "sha256-yKWLJx2IXXfrqXgR4/f/UxwaHG4uI+RTwqtBxc3fBaI=";
  };

  # Patches redirect OpenQP's ExternalProject-based build to use pre-built
  # nixpkgs packages for all external dependencies instead of downloading
  # and building them from source.
  patches = [
    # Adds "system" BLAS backend to oqp_functions.cmake that uses libraries
    # provided via OQP_BLAS_LIBRARIES/OQP_LAPACK_LIBRARIES instead of
    # find_package(BLAS) (which defaults to Intel MKL on x86_64 Linux).
    ./patches/oqp-functions.patch
    # Adds "system" to linalg_lib_options and creates no-op custom targets
    # for mctc-lib/multicharge/dftd4 before add_subdirectory(external) so
    # the ExternalProject_Add calls are skipped.
    ./patches/root-cmake.patch
    # Redirects libint, libxc, libecpint, tagarray, and DFT-D4 stack to
    # nix store paths; pre-fetches tagarray source; sets DFT-D4 runtime
    # sources to dummy files to avoid duplicate ninja outputs.
    ./patches/external-cmake.patch
    # Points libint Fortran headers and DFT-D4 module includes at nix
    # packages; links DFT-D4 by name (-ldftd4) instead of full paths;
    # skips DFT-D4 runtime install and corresponding-source bundling.
    ./patches/source-cmake.patch
    # Adapts dftd4_interface.F90 to the dftd4 v4.2.0 API where
    # new_d4_model takes (error, d4, mol) instead of (d4, mol).
    ./patches/dftd4-api.patch
    # Sets LINALG_LIB=system (bypasses find_package(BLAS) which defaults
    # to Intel MKL on x86_64 Linux) and defines OQP_SYSTEM_* placeholders
    # filled by substituteInPlace with nix store paths.
    ./patches/pyproject.patch
  ];

  nativeBuildInputs = [
    cmake
    ninja
    gfortran
    mpi
  ];

  build-system = [
    scikit-build-core
    setuptools
  ];

  dependencies = [
    numpy
    scipy
    cffi
    basis_set_exchange
    mpi4py
  ];

  # MPI runtime is needed by consumers that import oqp and use MPI parallelism.
  propagatedUserEnvPkgs = [ mpi ];

  buildInputs = [
    blas
    lapack
    libxc
    libecpint
    libintWithFortranHeaders
    grimmeCmake.mctc-lib
    grimmeCmake.multicharge
    grimmeCmake.dftd4
    mpi
  ];

  nativeCheckInputs = [
    mpiCheckPhaseHook
    pytestCheckHook
  ];

  dontUseCmakeConfigure = true;
  doCheck = true;

  # The full test suite has 2247 tests with heavy quantum chemistry calculations.
  # Use -x to stop on first failure and -v for verbose output.
  pytestFlags = [ "-x" "-v" "--tb=short" ];

  # Pass CMake build options via CMAKE_ARGS as recommended by upstream docs
  # (https://open-quantum-platform.github.io/openqp-docs/build-options/).
  # BUILD_TESTING is tied to doCheck so tests are only built when needed.
  env.CMAKE_ARGS = lib.concatStringsSep " " [
    (lib.cmakeBool "ENABLE_OPENMP" true)
    (lib.cmakeBool "ENABLE_MPI" true)
    (lib.cmakeBool "USE_LIBINT" true)
    (lib.cmakeBool "ENABLE_Formatter" false)
    (lib.cmakeBool "OQP_REUSE_EXTERNALS" false)
    (lib.cmakeBool "BUILD_TESTING" doCheck)
  ];

  # Fill in nix store paths in pyproject.toml cmake defines.
  # The pyproject.patch uses @PLACEHOLDER@ syntax for these values.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --subst-var-by BLAS_LIBRARIES '${lib.getLib blas}/lib/libblas.so' \
      --subst-var-by LAPACK_LIBRARIES '${lib.getLib lapack}/lib/liblapack.so' \
      --subst-var-by OQP_SYSTEM_LIBINT '${libintWithFortranHeaders}' \
      --subst-var-by OQP_SYSTEM_LIBXC '${libxc}' \
      --subst-var-by OQP_SYSTEM_LIBXC_INCLUDE '${lib.getDev libxc}/include' \
      --subst-var-by OQP_SYSTEM_LIBECPINT '${libecpint}' \
      --subst-var-by OQP_TAGARRAY_SOURCE '${tagarrayTarball}' \
      --subst-var-by OQP_SYSTEM_MCTC_LIB '${grimmeCmake.mctc-lib}' \
      --subst-var-by OQP_SYSTEM_MCTC_LIB_INCLUDE '${lib.getDev grimmeCmake.mctc-lib}/include' \
      --subst-var-by OQP_SYSTEM_MULTICHARGE '${grimmeCmake.multicharge}' \
      --subst-var-by OQP_SYSTEM_MULTICHARGE_INCLUDE '${lib.getDev grimmeCmake.multicharge}/include' \
      --subst-var-by OQP_SYSTEM_DFTD4 '${grimmeCmake.dftd4}' \
      --subst-var-by OQP_SYSTEM_DFTD4_INCLUDE '${lib.getDev grimmeCmake.dftd4}/include'
  '';

  pythonImportsCheck = [ "oqp" ];

  meta = with lib; {
    description = "Open Quantum Platform - quantum chemistry program centered on MRSF-TDDFT";
    homepage = "https://github.com/Open-Quantum-Platform/openqp";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "openqp";
  };
}
