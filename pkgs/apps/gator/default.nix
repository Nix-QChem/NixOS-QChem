{ lib, stdenv, fetchFromGitHub, buildPythonPackage
, psutil, numpy, mpi4py, adcc, pytest, openssh, mpi
, veloxchem
}:

#assert !blas.isILP64;

buildPythonPackage rec {
  pname = "gator";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "gator-program";
    repo = "gator";
    rev = "v${version}";
    sha256 = "0i37w8b720dyw1m4qfdcj8hpc8nskpn96466aljj61z9629slgd5";
  };

  propagatedBuildInputs = [
    numpy
    mpi4py
    adcc
    psutil
    mpi
    veloxchem
  ];

  # check phase does not run,
  # maybe fails to import the gator module
  doCheck = false;

  checkInputs = [
    pytest
    openssh
    mpi
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
    description = "Program for computational spectroscopy and calculations of molecular properties";
    homepage = "https://github.com/gator-program/gator";
    license = licenses.gpl3Only;
    maintainers = [ maintainers.markuskowa ];
  };
}

