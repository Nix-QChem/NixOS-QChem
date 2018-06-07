{ stdenv, pkgs, fetchFromGitHub, automake, autoconf, libtool
, openblas, gfortran
, ssh ? pkgs.openssh
, mpi ? pkgs.openmpi
} :

let
  version = "5.7";

in stdenv.mkDerivation {
  name = "ga-${version}";

  src = fetchFromGitHub {
    owner = "GlobalArrays";
    repo = "ga";
    rev = "v${version}";
    sha256 = "07i2idaas7pq3in5mdqq5ndvxln5q87nyfgk3vzw85r72c4fq5jh";
  };

  nativeBuildInputs = [ automake autoconf libtool ];
  buildInputs = [ mpi openblas gfortran ssh ];

  preConfigure = ''
    autoreconf -ivf
    configureFlagsArray+=( "--enable-unit-tests" \
                           "--enable-i8" \
                           "--with-mpi" \
                           "--with-mpi3" \
                           "--enable-eispack" \
                           "--enable-underscoring" \
                           "--with-blas8=${openblas}/lib -lopenblas" )
  '';

  doCheck = false; # does not work, test call evaluates wrong
 
  checkTarget = "check";

  enableParallelBuild = true;

  meta = with stdenv.lib; {
    description = "Globals arrays library";
    homepage = http://hpc.pnl.gov/globalarrays/;
   #license = licenses.bsd3;
    platforms = platforms.linux;
  };
}


