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
, openblas
, libxc
, libecpint
, mctc-lib
, multicharge
, dftd4
, mstore
, newScope
, pytest
, pytest-forked
, pytestCheckHook
}:

let
  /*
    OpenQP is ILP64-only (8-byte BLAS integers). numpy/scipy from nixpkgs
    use LP64 BLAS (libblas.so.3). If we link OpenQP against the blas-ilp64
    wrapper (also libblas.so.3), the dynamic linker may load only one
    libblas.so.3, causing ILP64/LP64 symbol collision (DSYEVD garbage INFO).
    Link the raw ILP64 OpenBLAS (libopenblas.so.0) directly instead: its
    SONAME differs from numpy's libblas.so.3, so both coexist in one process.
    This mirrors upstream CI: OpenQP links libopenblas (ILP64) while
    numpy/scipy use their own LP64 BLAS.
  */

  /* Use lib.makeScope to create a consistent set of cmake-built grimme
     libraries with ILP64 BLAS, so they can find each other via
     find_package(CONFIG) and propagate dependencies correctly.
     This mirrors the pattern used by CP2K in nixpkgs. */
  grimmeCmake = lib.makeScope newScope (self: {
    mctc-lib = mctc-lib.override { buildType = "cmake"; };
    mstore = mstore.override {
      buildType = "cmake";
      inherit (self) mctc-lib;
    };
    multicharge = (multicharge.override {
      buildType = "cmake";
      # openblas with blas64=true is ILP64 but doesn't have isILP64 attr;
      # overrideAttrs below adds it to satisfy nixpkgs assertions.
      blas = openblas // { isILP64 = true; };
      lapack = openblas // { isILP64 = true; };
      inherit (self) mctc-lib mstore;
    }).overrideAttrs (old: {
      buildInputs = [ openblas ];
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DWITH_ILP64=ON"
        "-DBLAS_LIBRARIES=${lib.getLib openblas}/lib/libopenblas.so"
        "-DLAPACK_LIBRARIES=${lib.getLib openblas}/lib/libopenblas.so"
      ];
    });
    dftd4 = (dftd4.override {
      buildType = "cmake";
      blas = openblas // { isILP64 = true; };
      lapack = openblas // { isILP64 = true; };
      inherit (self) mctc-lib mstore multicharge;
    }).overrideAttrs (old: {
      buildInputs = [ openblas ];
      propagatedBuildInputs = [ self.mctc-lib self.mstore self.multicharge ];
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DWITH_ILP64=ON"
        "-DBLAS_LIBRARIES=${lib.getLib openblas}/lib/libopenblas.so"
        "-DLAPACK_LIBRARIES=${lib.getLib openblas}/lib/libopenblas.so"
      ];
    });
  });

  # This is an OpenQP project and pinned in CMake. Must be kept in sync with the
  # version demanded by the OpenQP release
  tagarrayTarball = fetchurl {
    url = "https://github.com/Open-Quantum-Platform/tagarray/archive/refs/tags/v1.0.0.tar.gz";
    hash = "sha256-WQiWvNqtykw0ZkdNNe/wbtQJDELTej+N3aDe+DgzxsU=";
  };

in
buildPythonPackage (finalAttrs: {
  pname = "openqp";
  version = "1.3.1";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "Open-Quantum-Platform";
    repo = "openqp";
    rev = "v${finalAttrs.version}";
    hash = "sha256-yKWLJx2IXXfrqXgR4/f/UxwaHG4uI+RTwqtBxc3fBaI=";
  };

  # Patches redirect OpenQP's ExternalProject-based build to use pre-built
  # nixpkgs packages for all external dependencies instead of downloading
  # and building them from source.
  patches = [
    # Adds "system" BLAS backend to oqp_functions.cmake that uses libraries
    # provided via OQP_BLAS_LIBRARIES/OQP_LAPACK_LIBRARIES instead of
    # find_package(BLAS) (which defaults to Intel MKL on x86_64 Linux).
    ./oqp-functions.patch
    # Adds "system" to linalg_lib_options and creates no-op custom targets
    # for mctc-lib/multicharge/dftd4 before add_subdirectory(external) so
    # the ExternalProject_Add calls are skipped.
    ./root-cmake.patch
    # Redirects libxc, libecpint, tagarray, and DFT-D4 stack to
    # nix store paths; pre-fetches tagarray source; sets DFT-D4 runtime
    # sources to dummy files to avoid duplicate ninja outputs.
    ./external-cmake.patch
    # Points DFT-D4 module includes at nix packages; links DFT-D4
    # by name (-ldftd4) instead of full paths; skips DFT-D4 runtime
    # install and corresponding-source bundling.
    ./source-cmake.patch
    # Adapts dftd4_interface.F90 to the dftd4 v4.2.0 API where
    # new_d4_model takes (error, d4, mol) instead of (d4, mol).
    ./dftd4-api.patch
    # Makes bind(C) wrapper functions public in their Fortran modules.
    # gfortran 16 correctly does not export C-binding symbols for private
    # module procedures; upstream declared the Fortran entry points as
    # public but forgot the _C wrappers.
    ./bind-c-public.patch
    # Redirects test_cam_hessian.py's hardcoded /tmp work directories to
    # TMPDIR, so the nix build sandbox and non-sandboxed builds both use
    # a writable temporary directory.
    ./test-tmpdir.patch
    # Sets LINALG_LIB=system (bypasses find_package(BLAS) which defaults
    # to Intel MKL on x86_64 Linux) and defines OQP_SYSTEM_* placeholders
    # filled by substituteInPlace with nix store paths.
    ./pyproject.patch
  ];

  nativeBuildInputs = [
    cmake
    ninja
    gfortran
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
  ];

  buildInputs = [
    openblas
    libxc
    libecpint
    grimmeCmake.mctc-lib
    grimmeCmake.multicharge
    grimmeCmake.dftd4
  ];

  nativeCheckInputs = [
    pytest
    pytest-forked
    pytestCheckHook
  ];

  dontUseCmakeConfigure = true;
  doCheck = true;

  # Matches upstream CI. --forked is especially relevant, as multiple tests
  # manipulate python internals and must run independently.
  pytestFlags = [ "-q" "--tb=short" "--forked" "-rf" ];

  # These tests verify the DFT-D4 CMake build system packaging contract
  # (rpath sanitization, build info gates, exact patches). They fail because
  # our source-cmake.patch intentionally modifies the build system to use
  # nix packages instead of the upstream ExternalProject flow.
  disabledTestPaths = [ "tests/test_dftd4_shared_interface.py" ];

  preCheck = ''
    export OMP_NUM_THREADS=1
    export OMP_STACKSIZE=512M
    # The tests run from the source tree, but the Fortran library (liboqp.so)
    # and headers (include/oqp.h) are in the installed package directory.
    # Set OPENQP_ROOT so resolve_oqp_root() finds them. At runtime the
    # package's __file__ resolves correctly, so this is only needed for tests.
    # Use tail -1 because oqp prints "Failed to import mpi4py" to stdout when
    # mpi4py is absent (ENABLE_MPI=false).
    export OPENQP_ROOT=$(python3 -c "import oqp; print(oqp.__path__[0])" 2>&1 | tail -1)
  '';

  # Build system takes CMake options via environment for the strange pip+scipy build
  env.CMAKE_ARGS = lib.concatStringsSep " " [
    (lib.cmakeBool "ENABLE_OPENMP" true)
    (lib.cmakeBool "ENABLE_MPI" false)
    (lib.cmakeBool "USE_LIBINT" false)
    (lib.cmakeBool "ENABLE_Formatter" false)
    (lib.cmakeBool "OQP_REUSE_EXTERNALS" false)
    (lib.cmakeBool "BUILD_TESTING" finalAttrs.doCheck)
  ];

  # Fill in nix store paths in pyproject.toml cmake defines.
  # The pyproject.patch uses @PLACEHOLDER@ syntax for these values.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --subst-var-by BLAS_LIBRARIES '${lib.getLib openblas}/lib/libopenblas.so' \
      --subst-var-by LAPACK_LIBRARIES '${lib.getLib openblas}/lib/libopenblas.so' \
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
})
