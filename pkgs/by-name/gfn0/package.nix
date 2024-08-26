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
  version = "unstable-2024-07-18";

  src = fetchFromGitHub {
    owner = "pprcht";
    repo = pname;
    rev = "584cec4b47da23bf3634ef0dd798a1639fcc5e47";
    hash = "sha256-DULglQ144lLWK7sJkOEtMVmEIokOhYmrH6myBtfcNaA=";
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
