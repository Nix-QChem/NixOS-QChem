{ stdenv, fetchurl, requireFile, gfortran, fftw, protobuf, openblasCompat
, automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
}:

let
  version = "20191125";

in stdenv.mkDerivation {
  name = "qdng-${version}";

  src = requireFile {
    name = "qdng-${version}.tar.xz";
    sha256 = "19269bavjilml3yvbl5q5klxzvsxjjqpkbpgklr9km5j2nhzvrsd";
  };

  configureFlags = [ "--enable-openmp" "--with-blas=-lopenblas" ];

  enableParallelBuilding = true;

  preConfigure = ''
    ./genbs
  '';

  buildInputs = [ gfortran fftw protobuf openblasCompat
                  bzip2 zlib libxml2 flex bison ];
  nativeBuildInputs = [ automake autoconf libtool ];

  meta = {
    description = "Quantum dynamics program package";
    platforms = stdenv.lib.platforms.linux;
    maintainer = "markus.kowalewski@gmail.com";
  };

}
