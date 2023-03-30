{ lib, stdenv, fetchurl, requireFile, gfortran, fftw, protobuf
, blas, lapack
, automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
} :

assert (!blas.isILP64 && !lapack.isILP64);

let
  version = "20230330";

in stdenv.mkDerivation {
  pname = "qdng";
  inherit version;

  src = requireFile {
    name = "qdng-${version}.tar.xz";
    sha256 = "sha256-LO3oep4Sh1Lhkxr6qk4h7i/m7I6YyEov5ljDD6wa+pU=";
    message = "Get a copy of the QDng tarball from Markus...";
  };

  postPatch = ''
    patchShebangs tests/checktests.sh
  '';

  configureFlags = [
    "--enable-openmp"
    "--with-blas=-lblas"
    "--with-lapack=-llapack"
    "--disable-gccopt"
  ];

  enableParallelBuilding = false;

  preConfigure = ''
    ./genbs
  '';

  doCheck = true;

  buildInputs = [ fftw protobuf blas lapack
                  bzip2 zlib libxml2 flex bison ];
  nativeBuildInputs = [ automake autoconf libtool gfortran ];

  meta = with lib; {
    description = "Quantum dynamics program package";
    platforms = platforms.linux;
    maintainers = [ maintainers.markuskowa ];
    license = licenses.unfree;
  };
}
