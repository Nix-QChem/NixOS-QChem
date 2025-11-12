{
  stdenv,
  lib,
  fetchFromGitHub,
  python3,
  gfortran,
  mpi,
  scalapack,
  libcint,
  libxc,
  blas,
  lapack,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "molgw";
  version = "3.4";

  src = fetchFromGitHub {
    owner = "molgw";
    repo = "molgw";
    tag = "v${finalAttrs.version}";
    hash = "sha256-r+j4DU5KiJVdGvpq77zwqpYXgC52kiOuVlfVHOVyyg0=";
  };

  postPatch = ''
    patchShebangs src/noft/gitversion.sh
    substituteInPlace src/noft/gitversion.sh \
      --replace-fail 'name=`git rev-parse HEAD`' '${finalAttrs.version}'

    patchShebangs src/prepare_sourcecode.py
  '';

  preConfigure = ''
    cat > my_machine.arch << EOF
    PREFIX= $out
    OPENMP= -fopenmp

    CPPFLAGS=-DHAVE_MPI -DHAVE_SCALAPACK

    FC=mpifort
    FCFLAGS= -O2 -cpp

    CXX=g++
    CXXFLAGS= -O2

    LAPACK= -llapack -lgomp -lpthread -lm -ldl

    SCALAPACK= -lscalapack

    LIBXC_ROOT=${libxc}

    LIBINT_ROOT=

    LIBCINT=-lcint

    EOF
  '';

  nativeBuildInputs = [
    mpi
    gfortran
    python3
  ];

  buildInputs = [
    mpi
    libcint
    libxc
    blas
    lapack
    scalapack
  ];

  propagatedBuildInputs = [ mpi ];
  propagatedUserEnvPkgs = [ mpi ];

  meta = with lib; {
    description = "Many-body perturbation theory for atoms, molecules, and clusters";
    homepage = "https://www.molgw.org/";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.sheepforce ];
    platforms = [ "x86_64-linux" ];
  };
})
