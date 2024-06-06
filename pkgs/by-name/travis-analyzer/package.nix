{ stdenv, lib, fetchurl } :

stdenv.mkDerivation rec {
  pname = "travis-analyzer";
  version = "29Jul2022";

  src = fetchurl  {
    url = "http://www.travis-analyzer.de/files/travis-src-220729.tar.gz";
    sha256= "sha256-vcHkBi53ZuPitsJyPtOhp0VDoPkVbBKhOeSgOpc2Ej8=";
  };

  dontConfigure = true;
  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp exe/travis $out/bin/.
  '';

  meta = with lib; {
    description = "Molecular dynamics trajectory analyzer and visualizer";
    homepage = "http://www.travis-analyzer.de/";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
  };
}
