{ stdenv, fetchFromGitHub, gfortran, openblas, fftw, python2 } :

let
  version = "V2.0";

in stdenv.mkDerivation {
  name = "sharc-${version}";

  src = fetchFromGitHub {
    owner = "sharc-md";
    repo = "sharc";
    rev = "${version}";
    sha256 = "14zsmqpcxjsycfqwdknfl9jqlpdyjxf4kagjh1kyrfq0lyavh6dm";
  };

  nativeBuildInputs = [ ];
  buildInputs = [ gfortran openblas fftw python2 ];

  postPatch = ''
    # SHARC make file
    sed -i 's/^F90.*=.*/F90 = gfortran/' source/Makefile;
    sed -i 's/^LD.*=.*/LD = -lopenblas -lfftw3/' source/Makefile;
    sed -i 's:^EXEDIR.*=.*:EXEDIR = $out/bin:' source/Makefile;

    # WF overlap
    sed -i 's:^LALIB.*=.*:LALIB = -lopenblas -fopenmp:' wfoverlap/source/Makefile;

    rm bin/wfoverlap_ascii.x
    rm bin/wfoverlap.x
  '';

  buildPhase = ''
    cd wfoverlap/source
    make wfoverlap_ascii.x
    cd ../../source
    make
    cd ..
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -u bin/* $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Molecular dynamics (MD) program suite for excited states";
    homepage = https://www.sharc-md.org;
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}

