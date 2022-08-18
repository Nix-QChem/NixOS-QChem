{ lib, stdenv, fetchurl, requireFile, gfortran, fftw, protobuf
, blas, lapack
, automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
} :

assert (!blas.isILP64 && !lapack.isILP64);

let
  version = "20220818";

in stdenv.mkDerivation {
  pname = "qdng";
  inherit version;

  src = requireFile {
    name = "qdng-${version}.tar.xz";
    sha256 = "sha256-rw1XBITBr4ZP3/qVr3wh+NPHdAS5Th5nCIhIk6K1xG4=";
    message = "Get a copy of the QDng tarball from Markus...";
  };

  configureFlags = [
    "--enable-openmp"
    "--with-blas=-lblas"
    "--with-lapack=-llapack"
    "--disable-gccopt"
  ];

  enableParallelBuilding = true;

  preConfigure = ''
    ./genbs
  '';

  buildInputs = [ fftw protobuf blas lapack
                  bzip2 zlib libxml2 flex bison ];
  nativeBuildInputs = [ automake autoconf libtool gfortran ];

  meta = with lib; {
    description = "Quantum dynamics program package";
    platforms = platforms.linux;
    maintainer = [ maintainers.markuskowa ];
    license = licenses.unfree;
  };
}
