{ stdenv, lib, gfortran, fetchFromGitHub } :

stdenv.mkDerivation rec {
  pname = "packmol";
  version = "20.3.3";

  buildInputs = [ gfortran ];

  src = fetchFromGitHub {
    owner = "m3g";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-AVDaFkkFHYnMsuH2Xax4CaIOrS01SIPMfGuSzlMGiuY=";
  };

  dontConfigure = true;

  patches = [ ./MakeFortran.patch ];

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
