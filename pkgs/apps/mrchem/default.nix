{ lib, stdenv, fetchFromGitHub, cmake
, eigen, xcfun, mpi, nlohmann_json
, enableMpi ? mrcpp.enableMpi
, mrcpp
}:

stdenv.mkDerivation rec {
  pname = "mrchem";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "MRChemSoft";
    repo = "mrchem";
    rev = "v${version}";
    sha256 = "15sdd3kxl5pn3qsdsqryvyfc7fqp0lrgh7gdq4299l3qpr214y9r";
  };

  postPatch = ''
    substituteInPlace python/CMakeLists.txt --replace \
      'MRCHEM_EXECUTABLE ''${CMAKE_INSTALL_PREFIX}/' "MRCHEM_EXECUTABLE "
  '';

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    mrcpp
    eigen
    xcfun
    nlohmann_json
  ];

  cmakeFlags = [ "-DENABLE_OPENMP=ON" ]
    ++ lib.optional enableMpi "-DENABLE_MPI=ON";

  meta = with lib; {
    description = "Numerical real-space code for molecular electronic structure calculations";
    homepage = "https://mrchem.readthedocs.io";
    license = licenses.lgpl3Only;
    maintainer = [ maintainers.markuskowa ];
  };
}
