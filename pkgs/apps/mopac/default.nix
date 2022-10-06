{ stdenv, lib, gfortran, fetchFromGitHub, cmake, blas, lapack, python3Packages }:

assert blas.isILP64 == lapack.isILP64;

stdenv.mkDerivation rec {
  pname = "mopac";
  version = "22.0.4";

  src = fetchFromGitHub  {
    owner = "openmopac";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-FhYJS61BIYB6wk2GQaIuxGTEXiXPC0JePCoY2JdRhMo=";
  };

  nativeBuildInputs = [
    gfortran
    cmake
  ];

  buildInputs = [ blas lapack ];

  checkInputs = with python3Packages; [
    python
    numpy
  ];

  doCheck = true;

  meta = with lib; {
    description = "Semiempirical quantum chemistry";
    homepage = "https://github.com/openmopac/mopac";
    license = licenses.lgpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
