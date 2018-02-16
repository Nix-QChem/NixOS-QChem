{ stdenv, fetchFromGitHub, automake, autoconf, libtool
, openmpi, openblas, gfortran, ssh
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
  buildInputs = [ openmpi openblas gfortran ssh ];


  preConfigure = ''
    autoreconf -ivf
    configureFlagsArray+=( "--enable-unit-tests" \
                           "--enable-i8" \
                           "--with-mpi" \
                           "--with-mpi3" \
                           "--enable-peigs" \
                           "--enable-eispack" \
                           "--enable-underscoring" \
                           "--with-blas8=${openblas}/lib -lopenblas" )
  '';

  MPIEXEC="${openmpi}/bin/mpirun -np";

  doCheck = false; # does not work, test call evaluates wrong

  enableParallelBuild = true;

  checkPhase = "make check";

  meta = with stdenv.lib; {
    description = "Globals arrays library";
    homepage = http://hpc.pnl.gov/globalarrays/;
   #license = licenses.bsd3;
    platforms = platforms.linux;
  };
}


