{ stdenv, lib, fetchFromGitHub, cmake
, buildMolcasLib ? false
, buildMolcasExe ? false
, armadillo, blas, hdf5-cpp
} :

# Won't build together
assert buildMolcasExe -> !buildMolcasLib;

let
  libName = if buildMolcasLib
    then "libwfa_molcas.a"
    else "libwfa.a";

in stdenv.mkDerivation rec {
  pname = "libwfa";
  version = "2024-10-07";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "261d88f5a0d7bdf24ec09a426f0b45b97caf909a";
    hash = "sha256-F6LqmnVx64KTiMW+3X4jV1EoCioco1MQ+LBMjXtBBQs=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ armadillo blas hdf5-cpp ];

  env.NIX_CFLAGS_COMPILE = [ "-std=c++14" ];

  cmakeFlags = [ "-DARMA_HEADER=ON" ]
    ++ lib.optional buildMolcasLib "-DMOLCAS_LIB=ON"
    ++ lib.optional buildMolcasExe "-DMOLCAS_EXE=ON";

  installPhase = ''
    find
    mkdir -p $out/lib
    install -m 644 ./libwfa/${libName} $out/lib
  '' + lib.optionalString buildMolcasExe ''
    mkdir -p $out/bin
    install -m 755 ./libwfa/molcas/wfa_molcas.x $out/bin
  '';

  meta = with lib; {
    description = "Wave-function analysis tool library for quantum chemical applications";
    homepage = "https://github.com/libwfa/libwfa";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}

