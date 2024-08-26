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
  pname = "gfnff";
  version = "unstable-2024-08-02";

  src = fetchFromGitHub {
    owner = "pprcht";
    repo = pname;
    rev = "42963235cba66f81575f17b2dba8be7acf2a440d";
    hash = "sha256-Og/RL33Jz9okweq18NIKNsOYay+BF9qZHv9zlELMozI=";
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
    description = "A standalone library of the GFN-FF method. Extracted in large parts from the xtb program";
    license = with licenses; [ gpl3Only lgpl3Only ];
    homepage = "https://github.com/pprcht/gfnff";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
