{ stdenv
, fetchurl
, unzip
, lib
, autoPatchelfHook
}:

stdenv.mkDerivation rec {
  pname = "plt2cub";
  version = "1.0";

  src = fetchurl {
    url = "https://www.turbomole.org/wp-content/uploads/Tools/plt2cub.zip";
    hash = "sha256-Xc4A/teqhf7vMVfEFZHZTyD4Xr/katEJoGs+D/X1kQg=";
  };

  unpackPhase = ''
    runHook preUnpack

    unzip $src
    cd plt2cub

    runHook postUnpack
  '';

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp Linux/plt2cub.bin $out/bin/plt2cub

    runHook postInstall
  '';

  meta = with lib; {
    description = "Conversion utility for Turbomole's plt file to Cube format";
    homepage = "https://www.turbomole.org/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
