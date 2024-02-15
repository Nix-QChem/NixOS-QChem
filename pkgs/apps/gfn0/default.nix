{ stdenv
, lib
, cmake
, gfortran
, fetchFromGitHub
, blas
, lapack
}:

stdenv.mkDerivation rec {
  pname = "gfn0";
  version = "unstable-2023-07-22";

  src = fetchFromGitHub {
    owner = "pprcht";
    repo = pname;
    rev = "b0d68ec6b44a176db6c3684d7ccc9776e9a50394";
    hash = "sha256-257XGz5ZosPnbWjTgM2Bt7hH09ZQkTaW5Vu7udMSIhI=";
  };

  nativeBuildInputs = [
    cmake
    gfortran
  ];

  buildInputs = [
    blas
    lapack
  ];

  postInstall = ''
    substituteInPlace $out/lib/cmake/${pname}/${pname}-*.cmake \
      --replace "libgfn0.a" "libgfn0.${stdenv.hostPlatform.extensions.library}"
  '';

  meta = with lib; {
    description = "Standalone implementation of the GFN0-xTB method";
    license = with licenses; [ gpl3Only lgpl3Only ];
    homepage = "https://github.com/pprcht/gfn0";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
