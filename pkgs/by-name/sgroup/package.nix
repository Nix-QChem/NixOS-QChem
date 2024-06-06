{ stdenv
, fetchurl
, lib
}:

stdenv.mkDerivation rec {
  pname = "sgroup";
  version = "1.0";

  src = fetchurl {
    url = "https://elsevier.digitalcommonsdata.com/public-files/datasets/xp76bp3zxs/files/c315c05e-6734-43c1-9205-76b98281c043/file_downloaded";
    hash = "sha256-TNaoRQAFjjOmZCq7ZvQYGfxseEzo6mAwWim6HeS+Xig=";
  };

  unpackPhase = ''
    runHook preUnpack

    tar -xvf ${src}
    cd SpaceGroups

    runHook postUnpack
  '';

  postPatch = ''
    substituteInPlace Makefile \
      --replace "LDFLAGS = -L/usr/lib" "LDFLAGS =" \
      --replace "#FOPT    = -O3 -malign-double -malign-loops=4 -malign-jumps=4" "FOPT    = -O3 -malign-double -malign-loops=4 -malign-jumps=4"
  '';

  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin
    cp sgroup $out/bin
  '';

  meta = with lib; {
    description = "Determination of the space group and unit cell for a periodic solid";
    homepage = "https://elsevier.digitalcommonsdata.com/datasets/xp76bp3zxs/1";
    license = licenses.unfree;
    maintainers = [ maintainers.sheepforce ];
    platforms = [ "x86_64-linux" ];
  };
}
