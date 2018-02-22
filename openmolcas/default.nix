{ stdenv, fetchurl, cmake, gfortran
, openblas, hdf5-cpp, python3, texLive
} :

let
  version = "v18.0.o180115-1800";

in stdenv.mkDerivation {
  name = "openmolcas-${version}";

  src = fetchurl {
    url = "https://gitlab.com/Molcas/OpenMolcas/repository/${version}/archive.tar.bz2";
    sha256 = "1y06c51df2a3rqfk83kml1fj4zi47gml90k9gq8787zifycbhyxj";
  };

  nativeBuildInputs = [ cmake texLive ];
  buildInputs = [ gfortran openblas hdf5-cpp python3 ];

  cmakeFlags = [
    "-DOPENMP=ON"
    "-DLINALG=OpenBLAS"
    "-DTOOLS=OFF"
    "-DHDF5=OFF"
    "-DCTEST=ON"
    "-DOPENBLASROOT=${openblas}"
  ];

  postConfigure = ''
    mkdir -p $out/bin
    export PATH=$PATH:$out/bin
  '';

  postPatch = ''
    patchShebangs Tools/
  '';

  meta = with stdenv.lib; {
    description = "Quantum chemistry software package";
    homepage = https://gitlab.com/Molcas/OpenMolcas;
    license = with licenses; lgpl21;
    platforms = with platforms; linux;
  };
}

