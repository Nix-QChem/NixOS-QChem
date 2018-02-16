{ stdenv, fetchurl, cmake, gfortran, openblas, hdf5-fortran, python3, texLive } :

let
  version = "v18.0.o180115-1800";

in stdenv.mkDerivation {
  name = "openmolcas-${version}";

  src = fetchurl {
    url = "https://gitlab.com/Molcas/OpenMolcas/repository/${version}/archive.tar.bz2";
    sha256 = "0nak89s37yl1zlm70jr6qvaw1fvdfhn9m21v4n16gspbrxgw71bz";
  };

  nativeBuildInputs = [ cmake texLive ];
  buildInputs = [ gfortran openblas hdf5-fortran python3 ];

  cmakeFlags = [ "-DOPENMP=ON" "-DLINALG=OpenBLAS" "-DOPENBLASROOT=${openblas}" ];

  meta = with stdenv.lib; {
    description = "Quantum chemistry software package";
    homepage = https://gitlab.com/Molcas/OpenMolcas;
    license = with licenses; lgpl21;
    platforms = with platforms; linux;
  };
}

