{ stdenv, lib }:
stdenv.mkDerivation rec {
    pname = "travis-analyzer";
    version = "03Jun2020";

    src = fetchTarball  {
      url = "http://www.travis-analyzer.de/files/travis-src-200504-hf2.tar.gz";
      sha256= "1244w0sqb976c038hfkxvj4iym9nfbzhnisscrzx6vdr7q1g8pxh";
    };

    dontConfigure = true;
    enableParallelBuilding = true;
    installPhase = ''
      mkdir -p $out/bin
      cp exe/travis $out/bin/.
    '';

    meta = with lib; {
      description = "Molecular dynamics trajectory analyzer and visualizer";
      license = licenses.lgpl3Only;
      homepage = "http://www.travis-analyzer.de/";
      platforms = platforms.linux;
    };
  }
