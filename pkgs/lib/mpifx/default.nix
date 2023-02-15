{ stdenv
, lib
, fetchFromGitHub
, cmake
, fypp
, gfortran
, mpi
}:

stdenv.mkDerivation rec {
  pname = "mpifx";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "dftbplus";
    repo = pname;
    rev = version;
    hash = "sha256-FCR4252tYRfkP4updoNMzwHiGj3wq3/iTubn+paAiy4=";
  };

  nativeBuildInputs = [ cmake fypp gfortran ];

  propagatedBuildInputs = [ mpi ];

  meta = with lib; {
    description = "Modern Fortran wrappers around MPI routines";
    license = licenses.bsd2;
    homepage = "https://github.com/dftbplus/mpifx";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
