{ lib, stdenv, fetchFromGitHub, cmake, pugixml, python3, gtest }:

stdenv.mkDerivation rec {
    pname = "libecpint";
    version = "1.0.7";

    nativeBuildInputs = [
      cmake
      gtest
    ];

    buildInputs = [
      pugixml
    ];

    propagatedBuildInputs = [
      python3
    ];

    src = fetchFromGitHub {
      owner = "robashaw";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-2p2Ndl2TPeTo2310Jsk+TRSou+iYfJR2MdlVddzDPNE=";
    };

    cmakeFlags = [
      "-DLIBECPINT_MAX_L=7"
      "-DBUILD_SHARED_LIBS=ON"
    ];

    preCheck = ''
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/src:$(pwd)/external/Faddeeva
    '';
    doCheck = true;

    meta = with lib; {
      description = "C++ library for the efficient evaluation of integrals over effective core potentials";
      homepage = "https://github.com/robashaw/libecpint";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  }
