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
  version = "unstable-2024-02-14";

  src = fetchFromGitHub {
    owner = "pprcht";
    repo = pname;
    rev = "4d68ac1ab8df5999d3493715a86c13786bac6bfb";
    hash = "sha256-K1KwfrMqnXi1Mj3PDGYgHdG9WLuXFtrNqtfeL5wkDtI=";
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
