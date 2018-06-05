{ stdenv, cmake, fetchFromGitHub
, armadillo, hdf5-cpp
} :

let
  version = "QC44.a-git";

in stdenv.mkDerivation {
  name = "libwfa-${version}";

  src = fetchFromGitHub {
    owner = "libwfa";
    repo = "libwfa";
    rev = "efd3d5bafd403f945e3ea5bee17d43e150ef78b2";
    sha256 = "0qzs8s0pjrda7icws3f1a55rklfw7b94468ym5zsgp86ikjf2rlz";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ armadillo hdf5-cpp ];

  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs ./configure
  '';

  cmakeFlags = [
    "-DMOLCAS_LIB=ON"
    "-DMOLCAS_EXE=ON"
    "-DHDF5_DIR=${hdf5-cpp}"
  ];

#  installPhase = ''
#    mkdir -p $out/lib;
#    cp libwfa/libwfa_molcas.a $out/lib
#  '';

  meta = with stdenv.lib; {
    description = "Wave-function analysis tool library for quantum chemical applications";
    homepage = https://github.com/libwfa/libwfa;
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}

