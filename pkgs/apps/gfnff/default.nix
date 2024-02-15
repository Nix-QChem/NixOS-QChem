{ stdenv
, lib
, cmake
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

  nativeBuildInputs = [
    cmake
    gfortran
  ];

  buildInputs = [
    blas
    lapack
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=${if stdenv.hostPlatform.isStatic then "OFF" else "ON"}"
  ];

  postInstall = ''
    substituteInPlace $out/lib/cmake/${pname}/${pname}-*.cmake \
      --replace "libgfnff.a" "libgfnff.${stdenv.hostPlatform.extensions.library}"
  '';

  meta = with lib; {
    description = "A standalone library of the GFN-FF method. Extracted in large parts from the xtb program";
    license = with licenses; [ gpl3Only lgpl3Only ];
    homepage = "https://github.com/pprcht/gfnff";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
