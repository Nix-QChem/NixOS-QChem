{ lib, stdenv, fetchurl, requireFile, gfortran, fftw, protobuf
, blas, lapack
, automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
} :

assert (!blas.isILP64 && !lapack.isILP64);

let
  version = "20220318";

in stdenv.mkDerivation {
  pname = "qdng";
  inherit version;

  src = requireFile {
    name = "qdng-${version}.tar.xz";
    sha256 = "187xzl361gigmqxl4vb8d816s99x80gkab6qddzk91n2vx6q9g8h";
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
