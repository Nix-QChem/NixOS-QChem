{ lib, stdenv, fetchFromGitHub, cmake
, eigen
, enableMpi ? false
, mpi
}:

stdenv.mkDerivation rec {
  pname = "mrcpp";
  version = "1.4.2";

  src = fetchFromGitHub {
    owner = "MRChemSoft";
    repo = "mrcpp";
    rev = "v${version}";
    sha256 = "sha256-zWcUHaJ76IXei+8KS32RpdZ39dmRJGkp/Ozlx9eEn3Q=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    eigen
  ];

  propagatedBuildInputs = lib.optional enableMpi [ mpi ];

  cmakeFlags = [
    "-DENABLE_OPENMP=ON"
  ] ++ lib.optional enableMpi "-DENABLE_MPI=ON";

  passthru = { inherit enableMpi; };

  postFixup = ''
    substituteInPlace $out/share/cmake/MRCPP/MRCPPConfig.cmake --replace \
        'PATHS ''${PACKAGE_PREFIX_DIR}/' "PATHS "
  '';

  meta = with lib; {
    description = "General purpose numerical mathematics library based on multiresolution analysis";
    homepage = "https://mrcpp.readthedocs.io";
    license = licenses.lgpl3Only;
    maintainers = [ maintainers.markuskowa ];
  };
}
