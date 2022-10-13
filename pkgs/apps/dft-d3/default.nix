{ lib, stdenv, fetchFromGitHub, gfortran } :

stdenv.mkDerivation rec {
  pname = "dftd3-lib";
  version = "0.10"; # Equivalent to 3.2rev0 of the original

  nativeBuildInputs = [ gfortran ];

  src = fetchFromGitHub {
    owner = "dftbplus";
    repo = pname;
    rev = version;
    hash = "sha256-lda0eEb/QoMG2Sb1/VhJSr+fJcu2wvy1hqw+rVDhe2w=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp prg/dftd3 $out/bin/.
  '';

  hardeningDisable = [ "format" ];

  meta = with lib; {
    description = "Dispersion correction for DFT";
    homepage = "https://github.com/dftbplus/dftd3-lib";
    platforms = platforms.unix;
    license = licenses.gpl1Only;
  };
}
