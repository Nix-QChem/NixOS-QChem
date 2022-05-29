{ lib, stdenv, fetchurl, wrapQtAppsHook, qmake, qtscript, qtsvg, blas-ilp64, lapack-ilp64
, glew, boost, eigen, libGLU }:

stdenv.mkDerivation rec {
  pname = "IboView";
  version = "20211019";

  src = fetchurl {
    url = "http://www.iboview.org/bin/ibo-view.${version}.tar.bz2";
    sha256 = "0mrspsdl30n2v5ymrig7yqq6xmpad9r3zr0da5hp7b8gzyzkg61f";
  };

  # Getting multiple arguments from the environment variable as by documentation does not work.
  patches = [ ./blas.patch ];
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

  meta = with lib; {
    description = "Calculator and visualiser for Intrinsic Bond Orbitals";
    homepage = "http://www.iboview.org/index.html";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "iboview";
    maintainers = [ maintainers.sheepforce ];
    broken = true;  # requires an update/patch for gcc-10/11
  };
}
