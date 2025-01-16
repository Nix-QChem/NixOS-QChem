{ buildPythonPackage
, lib
, fetchFromGitHub
, boost
, cmake
, blas
, lapack
, libxml2
, hdf5-mpi
, fftw
, mpi
, perl
, python
, numpy
, h5py
, pandas
, scipy
, pyscf
, mpi4py
}:

buildPythonPackage rec {
  pname = "qmcpack";
  version = "unstable-2025-01-16";

  src = fetchFromGitHub {
    owner = "QMCPACK";
    repo = "qmcpack";
    rev = "0373d2c6c20ef45412805cd973b522e5a988d832";
    sha256 = "sha256-CyCGj8cY907RjkMZexnMyC8wEtuXcDYyJe/jeWrWDg8=";
  };

  format = "other";

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    boost
    blas
    lapack
    libxml2
    hdf5-mpi
    fftw
  ];

  cmakeFlags = [
    "-DQMC_MPI=ON"
    "-DQMC_OMP=ON"
    "-DBUILD_AFQMC=ON"
    "-DCMAKE_C_COMPILER=${lib.getDev mpi}/bin/mpicc"
    "-DCMAKE_CXX_COMPILER=${lib.getDev mpi}/bin/mpicxx"
  ];

  propagatedBuildInputs = [
    mpi
    numpy
    h5py
    pandas
    scipy
    pyscf
    mpi4py
    perl
  ];

  # Install the python utility programs of QMCPACK
  postInstall =
    let
      pythonScripts = [
        "convert-gamess-ecp-to-qmcpack"
        "determinants_tools.py"
      ];
      perlScripts = [
        "OptProgress.pl"
        "PlotDMC.pl"
        "energy.pl"
      ];
    in
    ''
      mkdir -p $out/${python.sitePackages}

      for F in ${builtins.toString (pythonScripts ++ perlScripts)}; do
        cp ../utils/$F $out/bin/.
      done

      cp ../utils/afqmctools/bin/* $out/bin/.
      cp -r ../utils/afqmctools/afqmctools $out/${python.sitePackages}/.

      patchShebangs $out/bin/.
    '';

  pythonImportsCheck = [ "afqmctools" ];

  meta = with lib; {
    description = "Many-body ab initio Quantum Monte Carlo code for electronic structure calculations";
    homepage = "https://www.qmcpack.org";
    license = licenses.ncsa;
    maintainers = [ maintainers.markuskowa ];
  };
}
