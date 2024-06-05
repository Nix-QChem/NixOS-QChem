{ lib, stdenv, fetchFromGitHub, cmake, gfortran } :

stdenv.mkDerivation rec {
  pname = "dftd3";
  version = "3.2.1"; # Equivalent to 3.2rev0 of the original

  nativeBuildInputs = [ gfortran cmake ];

  src = fetchFromGitHub {
    owner = "loriab";
    repo = pname;
    rev = "8e5463eafbaa0130a1aa26b8ee8ed57b1c3ffef0";
    hash = "sha256-rC8JORAxlYjURfocCY4LRQmONeRaRAy876++mHx9xAM=";
  };

  hardeningDisable = [ "format" ];

  meta = with lib; {
    description = "Dispersion correction for DFT";
    homepage = "https://github.com/loriab/dftd3";
    platforms = platforms.unix;
    license = licenses.gpl1Only;
  };
}
