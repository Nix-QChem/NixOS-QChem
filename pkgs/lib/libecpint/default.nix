{ lib, stdenv, fetchFromGitHub, fetchpatch, cmake, pugixml, python3, gtest }:

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

    patches = [
      # Remove on next release, ensures C++14 and GTest compatibility
      (fetchpatch {
        url = "https://github.com/robashaw/libecpint/commit/8e788d4ea9b74e464dd834441369e3e8488256d9.patch";
        hash = "sha256-wcf/b/2+9PabtJMBrj0aTD8owoFt/wMj0f7nXVUucrI=";
      })
    ];

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
