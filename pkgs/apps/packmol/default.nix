{ stdenv, lib, gfortran, fetchFromGitHub } :

stdenv.mkDerivation rec {
  pname = "packmol";
  version = "20.11.0";

  buildInputs = [ gfortran ];

  src = fetchFromGitHub {
    owner = "m3g";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-ABjXdqXO3Id14c/zDvS79GsAJXQeHRPxeXZh9lITiBU=";
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
