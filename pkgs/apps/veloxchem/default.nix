{ buildPythonPackage, lib, fetchFromGitLab, rsync
, mpi, xtb, blas
, mpi4py, numpy, pybind11, h5py, psutil, geometric
, pytest, pytest-cov, openssh
}:

assert !blas.isILP64;

buildPythonPackage rec {
  pname = "veloxchem";
  version = "2022-01-07";

  src = fetchFromGitLab {
    owner = pname;
    repo = pname;
    rev = "17bbbb43972baafeef517bee7ff147e2c04fa28e";
    sha256 = "1piqm9hsbgm0rf8xakf4c5jhggl7n362mvq0zn8a1x1x00k0bg1i";
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
    openssh # needed for openmpi
    pytest
  ];

  checkPhase = ''
    export OMP_NUM_THREADS=1
    export OMPI_MCA_rmaps_base_oversubscribe=1
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

