{ stdenv, fetchurl, cmake, gfortran, perl
, openblas, hdf5-cpp, python3, texLive
, pythonPackages
} :

let
  version = "v18.0.o180526-1800";

in stdenv.mkDerivation {
  name = "openmolcas-${version}";

  src = fetchurl {
    url = "https://gitlab.com/Molcas/OpenMolcas/repository/${version}/archive.tar.bz2";
    sha256 = "0kh0zd8jrhr92dcj7r8fhqia1ryzwr0sbxzfk3mk1a3zp9wmig8j";
  };

  nativeBuildInputs = [ perl cmake texLive ];
  buildInputs = [ gfortran openblas hdf5-cpp python3 pythonPackages.six ];

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

