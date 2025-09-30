{ stdenv, lib, gfortran, fetchFromGitHub } :

stdenv.mkDerivation rec {
  pname = "packmol";
  version = "21.1.0";

  buildInputs = [ gfortran ];

  src = fetchFromGitHub {
    owner = "m3g";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-PtLbSJj7qMmqX488sH1Wy25lWselT3MhoXHZerkgBTc=";
  };

  dontConfigure = true;

  postPatch = ''
    substituteInPlace Makefile \
      --replace "/usr/bin/gfortran" "gfortran"
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -p packmol $out/bin
  '';

  hardeningDisable = [ "format" ];

  meta = with lib; {
    description = "Generating initial configurations for molecular dynamics";
    homepage = "http://m3g.iqm.unicamp.br/packmol/home.shtml";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
