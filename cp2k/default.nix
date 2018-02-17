{ stdenv, fetchurl, python, gfortran, openblas
, fftw, libint, libxc
} :

let
  version = "5.1";

in stdenv.mkDerivation {
  name = "cp2k-${version}";

  src = fetchurl {
    url = "https://sourceforge.net/projects/cp2k/files/cp2k-${version}.tar.bz2";
    sha256 = "04j4j04sn0w4a91xidfrqswa01y6jiyy24441cpahkrmjfsi6dp2";
  };

  nativeBuildInputs = [ python ];
  buildInputs = [ gfortran fftw libint libxc openblas ];

  makeFlags = [
    "ARCH=Linux-x86-64-gfortran"
    "VERSION=ssmp"
  ];

  doCheck = true;

  postPatch = ''
    cat >arch/Linux-x86-64-gfortran.ssmp <<EOF
      CC         = gcc
      CPP        =
      FC         = gfortran
      LD         = gfortran -fopenmp -L${openblas}/lib -lopenblas
      AR         = ar -r
      FFTW_INC=${fftw}/include
      FFTW_LIB=-L${fftw}/lib -lfftw3 -lfftw3_threads
      LIBINT_INC=${libint}/include
      LIBINT_LIB=-L${libint}/lib
      LIBXC_INC=${libxc}/include
      LIBXC_LIB=-L${libxc}/lib -lxc -lxcf90
      LIBLAPACK_LIB=-L${openblas}/lib -lopenblas
      DFLAGS     = -D__FFTW3 -D__LIBXC \
                   -D__LIBINT_MAX_AM=7 -D__LIBDERIV_MAX_AM1=6 -D__MAX_CONTR=4
      CPPFLAGS   =
      FCFLAGS    = $(DFLAGS) -O2 -ffast-math -ffree-form -ffree-line-length-none \
               -fopenmp -ftree-vectorize -funroll-loops \
               -I$(FFTW_INC) -I$(LIBINT_INC) -I$(LIBXC_INC)
      LDFLAGS    = $(FCFLAGS)
      LIBS       =  $(LIBLAPACK_LIB) $(FFTW_LIB) $(LIBXC_LIB)
      #                 $(LIBINT_LIB)/libderiv.a\
      #                 $(LIBINT_LIB)/libint.a
EOF

  '';

  preBuild = ''
    cd makefiles
  '';

  checkPhase = ''
    make test
  '';

  installPhase = ''
    mkdir -p $out/bin

    cp exe/Linux-x86-64-gfortran/* $out/bin
    ln -s $out/bin/cp2k.ssmp $out/bin/cp2k
  '';

  meta = with stdenv.lib; {
    description = "Quantum chemistry and solid state physics program";
    homepage = https://www.cp2k.org;
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}

