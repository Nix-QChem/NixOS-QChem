{ stdenv
, lib
, gfortran
, fetchFromGitHub
, cmake
, git
, blas
, lapack
, mpi
, mpiCheckPhaseHook
, hdf5-fortran-mpi
, python3
}:

assert !blas.isILP64 && !lapack.isILP64;

stdenv.mkDerivation rec {
  pname = "NECI";
  version = "unstable-2023-06-20";

  src = fetchFromGitHub {
    owner = "ghb24";
    repo = "NECI_STABLE";
    rev = "558e88c5ae6c30d0505a9badbc69111be0866ba1";
    hash = "sha256-f/OS/Bz80H2xgBanBfsPXZ5K8rm3VYFl1f4QtIJ0VSw=";
    # Requires an ancient version of Fypp to work, which is included as submodule
    fetchSubmodules = true;
  };

  patches = [
    # Replaces a deprecated RawConfigParser.readfp() with RawConfigParser.read_file()
    ./python.patch
  ];

  nativeBuildInputs = [
    gfortran
    cmake
    git
    python3 # Only required at build time for Fypp and preprocessing
  ];

  buildInputs = [
    blas
    lapack
    hdf5-fortran-mpi
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp ./bin/* $out/bin
  '';

  propagatedBuildInputs = [ mpi ];
  propagatedUserEnvPkgs = [ mpi ];

  nativeCheckInputs = [ mpiCheckPhaseHook ];
  doCheck = true;

  passthru = { inherit mpi; };

  meta = with lib; {
    description = "Stochastic Quantum Monte Carlo solver for CI-like problems";
    homepage = "https://github.com/ghb24/NECI_STABLE";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
