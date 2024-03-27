{ stdenv
, lib
, meson
, ninja
, pkg-config
, gfortran
, fetchFromGitHub
, blas
, lapack
}:

stdenv.mkDerivation rec {
  pname = "gfn0";
  version = "unstable-2024-03-07";

  src = fetchFromGitHub {
    owner = "pprcht";
    repo = pname;
    rev = "1701599ca4298ecb5c3741a9e56d67ce03e9e4c3";
    hash = "sha256-slUShllJ3shUZaEnEIhy6QbDzteNSlbLrokPKgYhG7I=";
  };

  patches = [ ./build.patch ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gfortran
  ];

  buildInputs = [
    blas
    lapack
  ];

  mesonFlags = [
    "-Dla_backend=netlib"
  ];

  meta = with lib; {
    description = "Standalone implementation of the GFN0-xTB method";
    license = with licenses; [ gpl3Only lgpl3Only ];
    homepage = "https://github.com/pprcht/gfn0";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
