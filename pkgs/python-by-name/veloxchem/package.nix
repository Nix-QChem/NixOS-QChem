{ buildPythonPackage, lib, fetchFromGitLab, rsync
, mpiCheckPhaseHook, mpi, xtb, blas
, mpi4py, numpy, pybind11, h5py, psutil, geometric
, pytest, pytest-cov, openssh
}:

assert !blas.isILP64;

buildPythonPackage rec {
  pname = "veloxchem";
  version = "2022-02-24";

  src = fetchFromGitLab {
    owner = pname;
    repo = pname;
    rev = "401d1c367931e72e0ca634892887c67d8237189e";
    sha256 = "0xd8xlx5z319fqvi3kqfj7dlm9axa8sviqgyrlk6sbz3lmngg2px";
  };

  preBuild = ''
    export VLX_NUM_BUILD_JOBS=$NIX_BUILD_CORES

    export MPICXX=mpicxx

    # The setup script requires OPENBLASROOT or MKLROOT
    ${if blas.passthru.provider.pname == "openblas"
      then "export OPENBLASROOT=${blas.passthru.provider.dev}"
      else if blas.passthru.provider.pname == "mkl"
      then "export MKLROOT=${blas.passthru.provider.dev}"
      else ""}
  '';

  nativeBuildInputs = [
    rsync
    mpi
    pytest
  ];

  buildInputs = [
    blas.passthru.provider.outPath
  ];

  propagatedBuildInputs = [
    numpy
    h5py
    geometric
    mpi
    pybind11
    psutil
    mpi4py
    xtb
  ];

  checkInputs = [
    pytest
  ];

  nativeCheckInputs = [
    mpiCheckPhaseHook
    pytest
    openssh
  ];

  checkPhase = ''
    runHook preCheck

    cd python_tests
    mpirun -np 2 python3 -m pytest

    runHook postCheck
  '';

  meta = with lib; {
    description = "Quantum chemistry software for the calculation of molecular properties and spectroscopies";
    homepage = "https://veloxchem.org";
    license = [ licenses.lgpl3 ];
    maintainers = [ maintainers.markuskowa ];
    broken = true; # Needs an update to the latest version
  };
}

