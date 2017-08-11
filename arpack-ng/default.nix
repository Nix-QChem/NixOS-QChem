{ stdenv, lib, copyPathsToStore, fetchurl, autoconf, automake, gettext, libtool
, gfortran, blas, liblapack }:

with stdenv.lib;

let
  version = "3.5.0";
in
stdenv.mkDerivation {
  name = "arpack-${version}";

  src = fetchurl {
    url = "https://github.com/opencollab/arpack-ng/archive/${version}.tar.gz";
    sha256 = "0f8jx3fifmj9qdp289zr7r651y1q48k1jya859rqxq62mvis7xsh";
  };

  nativeBuildInputs = [ autoconf automake gettext libtool ];
  buildInputs = [ gfortran blas liblapack ];

  doCheck = true;

  BLAS_LIBS = "-L${blas}/lib -lblas";

#FFLAGS = optional openblas.blas64 "-fdefault-integer-8";

  preConfigure = ''
    ./bootstrap
  '';

  meta = {
    homepage = http://github.com/opencollab/arpack-ng;
    description = ''
      A collection of Fortran77 subroutines to solve large scale eigenvalue
      problems.
    '';
    license = stdenv.lib.licenses.bsd3;
    platforms = stdenv.lib.platforms.unix;
  };
}
