{ stdenv, fetchFromGitHub, automake, autoconf, libtool
, openmpi, openblas, gfortran
} :

let
  version = "5.6.3";

in stdenv.mkDerivation {
  name = "ga-${version}";

  src = fetchFromGitHub {
    owner = "GlobalArrays";
    repo = "ga";
    rev = "v${version}";
    sha256 = "0dgrli9rdxffzl0nd3998fbnlnlibx7ahid2v0nhis1r1i71k1dn";
  };

  nativeBuildInputs = [ automake autoconf libtool ];
  buildInputs = [ openmpi openblas gfortran ];

  configureFlags = [ "--with-tcgmsg"
                     "--with-mpi"
                     "--enable-peigs"
                     "--enable-underscoring"
                     "--with-blas8=${openblas}/lib -lopenblas" ];

  preConfigure = ''
    autoreconf
#   aclocal \
#    && automake --gnu --add-missing \
#    && autoconf
  '';

#  cmakeFlags = [
#    "-DENABLE_F77=ON"
#    "-DMPI_MT=OFF"
#    "-DENABLE_CXX=ON"
#    "-DENABLE_I8=ON"
#    "-DENABLE_ARMCI_MEM_OPTION=ON"
#  ];


  doCheck = true;

  enableParallelBuild = true;

  checkPhase = "make test";

  meta = with stdenv.lib; {
    description = "Globals arrays";
    homepage = https://;
#license = with licenses; gpl2;
    platforms = with platforms; linux;
  };
}


