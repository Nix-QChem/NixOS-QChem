{ lib, stdenv, fetchurl, requireFile, gfortran, fftw, protobuf
, blas, lapack
, automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
} :

assert (!blas.isILP64 && !lapack.isILP64);

let
  version = "20211209";

in stdenv.mkDerivation {
  pname = "qdng";
  inherit version;

  src = requireFile {
    name = "qdng-${version}.tar.xz";
    sha256 = "0y3kl5qkzzh0nkjz4ljm0iinhxdw04d6bs7i623bah2g93b9fy5y";
    message = "Get a copy of the QDng tarball from Markus...";
  };

  configureFlags = [
    "--enable-openmp"
    "--with-blas=-lblas"
    "--with-lapack=-llapack"
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
