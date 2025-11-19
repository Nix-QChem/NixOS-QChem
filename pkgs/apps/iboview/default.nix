{ lib, stdenv, fetchurl, wrapQtAppsHook, qmake, qtscript, qtsvg, blas-ilp64, lapack-ilp64
, glew, boost, eigen, libGLU, unzip }:

stdenv.mkDerivation rec {
  pname = "IboView";
  version = "20211019-RevA";

  src = fetchurl {
    url = "http://www.iboview.org/bin/ibo-view.${version}.zip";
    sha256 = "sha256-SK6jb4mZZjG2IcVx7FanPvG5vXABjxE2hb1GHrHHkQU=";
  };

  unpackPhase = ''
    ${unzip}/bin/unzip ${src}
    cd ibo-view.${version}
  '';

  patches = [
    # Ensure correct BLAS linking. The involved setup in main.pro does not work here
    ./blas.patch

    # Fix compatibility with GCC >= 11
    ./gcc.patch
  ];
  postPatch = ''
    substituteInPlace main.pro \
      --subst-var-by BLAS ${blas-ilp64} \
      --subst-var-by LAPACK ${lapack-ilp64}
  '';

  nativeBuildInputs = [ wrapQtAppsHook qmake ];

  buildInputs = [
    eigen
    blas-ilp64
    lapack-ilp64
    glew
    boost
    qtscript
    qtsvg
    libGLU
  ];

  # Standard QMake installation fails.
  installPhase = ''
    mkdir -p $out/bin
    cp iboview $out/bin/.
  '';

  qtWrapperArgs = [
    # Required on wayland to force xwayland usage. Graphics issues otherwise.
    "--set-default QT_QPA_PLATFORM xcb"
  ];

  meta = with lib; {
    description = "Calculator and visualiser for Intrinsic Bond Orbitals";
    homepage = "http://www.iboview.org/index.html";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "iboview";
    maintainers = [ maintainers.sheepforce ];
  };
}
