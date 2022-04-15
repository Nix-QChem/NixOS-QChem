{ lib, stdenv, fetchFromGitHub, fetchpatch, cmake
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

  patches = [ (fetchpatch {
    name = "gcc-patch";
    url = "https://github.com/MRChemSoft/mrchem/commit/c1959c688a6e159945d6281599b0de2143c89d25.patch";
    sha256 = "014vh5wl1l4a5xqxfwacrpb3im7knqjp2vmcbikfnmc1czw0s267";
  })];

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
