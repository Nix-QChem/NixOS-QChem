{ stdenv, fetchurl, gfortran, mesa_glu, xorg } : 

stdenv.mkDerivation rec {
  version = "5.7";
  name = "molden-${version}";

  prePatch = ''
     substituteInPlace ./makefile --replace '-L/usr/X11R6/lib'  "" \
                                  --replace '-I/usr/X11R6/include' "" \
                                  --replace '/usr/local/' $out/ \
                                  --replace 'sudo' "" \
				  --replace '-C surf depend' '-C surf' 
     sed -in '/^# DO NOT DELETE THIS LINE/q;' surf/Makefile
  '';

  preInstall = ''
     mkdir -p $out/bin
     '';

  src = fetchurl {
    url = "ftp://ftp.cmbi.ru.nl/pub/molgraph/molden/molden5.7.tar.gz";
    sha256 = "0x6ryga0dwrkylc8pb93f9w6ypska06kq7d0rxb8151jnndg9glf";
  };

  enableParallelBuilding = true;

  buildInputs = [ gfortran mesa_glu xorg.libX11 xorg.libXmu ];

  meta = {
     description = "Display and manipulate molecular structures";
     homepage    =  http://www.cmbi.ru.nl/molden/;
     license = {
	fullName = "Free for academic/non-profit use.";
	shortName = "academic use";
	url = http://www.cmbi.ru.nl/molden/CopyRight.html;
     };
     platforms = [ "x86_64-linux" "i686-linux" ]; 
  };
}

