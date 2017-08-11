{ stdenv, fetchurl, gfortran, perl }:

let 
  version = "2.2.3";
in 
  stdenv.mkDerivation {
    name = "libxc-${version}";
    src = fetchurl {
      url = "http://www.tddft.org/programs/octopus/down.php?file=libxc/libxc-${version}.tar.gz";
      sha256 = "1rv8vsf7zzw0g7j93rqcipzhk2pj1iq71bpkwf7zxivmgavh0arg";
    };

    buildInputs = [ gfortran ];
    nativeBuildInputs = [ perl ];
    outputs = [ "out" "dev" ];

    meta = {
      description = "lLibrary of exchange-correlation functionals for density-functional theory";
      homepage = http://octopus-code.org/wiki/Libxc;
      licenses = stdenv.lib.licenses.gpl3;
      platforms = stdenv.lib.platforms.linux;
    };
  }

