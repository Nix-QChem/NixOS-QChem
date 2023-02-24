{ stdenv
, lib
, fetchFromGitHub
, cmake
, fypp
, gfortran
, mpifx
, lapack
, scalapack
}:

assert !lapack.isILP64 && !scalapack.isILP64;

stdenv.mkDerivation rec {
  pname = "scalapackfx";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "dftbplus";
    repo = pname;
    rev = version;
    hash = "sha256-7vjRtlK9awrNieI1OBBDuRDPdgeR66U2X74Z4V2twpI=";
  };

  nativeBuildInputs = [ cmake fypp gfortran ];

  buildInputs = [ mpifx lapack scalapack ];

  cmakeFlags = [
    "-DSCALAPACK_LIBRARY=${scalapack}/lib/libscalapack.so"
    "-DLAPACK_LIBRARY=${lapack}/lib/liblapack.so"
  ];

  meta = with lib; {
    description = "Modern Fortran wrappers around ScaLAPACK routines";
    license = licenses.bsd2;
    homepage = "https://github.com/dftbplus/scalapackfx";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
