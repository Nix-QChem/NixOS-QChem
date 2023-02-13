{ buildPythonPackage, lib, fetchFromGitLab, rsync
, mpi, xtb, blas
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

  checkPhase = ''
    export OMP_NUM_THREADS=1
    export OMPI_MCA_rmaps_base_oversubscribe=1
    export OMPI_MCA_plm_rsh_agent=${lib.getBin openssh}/bin/ssh
    export MV2_ENABLE_AFFINITY=0
    # Fix to make mpich run in a sandbox
    export HYDRA_IFACE=lo

    cd python_tests
    mpirun -np 2 python3 -m pytest
  '';

  meta = with lib; {
    description = "Quantum chemistry software for the calculation of molecular properties and spectroscopies";
    homepage = "https://veloxchem.org";
    license = [ licenses.lgpl3 ];
    maintainers = [ maintainers.markuskowa ];
  };
}

