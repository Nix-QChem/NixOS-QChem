{ stdenv
, lib
, fetchFromGitHub
, boost
, swig
}:

stdenv.mkDerivation rec {
  pname = "Autodock-Vina";
  version = "1.2.3";

  src = fetchFromGitHub {
    owner = "ccsb-scripps";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-oOpwhRmpS5WfnuqxkjxGsGtrofPxUt8bH9ggzm5rrR8=";
  };

  postPatch = ''
    patchShebangs ./
  '';

  configurePhase = ''
    substituteInPlace build/linux/release/Makefile \
      --replace 'BOOST_INCLUDE = $(BASE)/include' 'BOOST_INCLUDE = ${boost}/include' \
      --replace 'C_PLATFORM=-static -pthread' 'C_PLATFORM=-pthread' \
      --replace 'GPP=/usr/bin/g++' "GPP=$NIX_CC/bin/$CXX"

    substituteInPlace build/makefile_common \
      --replace "GIT_VERSION := \$(shell git describe --abbrev=7 --dirty --always --tags | sed 's/dirty/mod/g')" 'GIT_VERSION := ${version}' \
  '';

  buildInputs = [ boost swig ];

  preBuild = "cd build/linux/release";

  installPhase = ''
    mkdir -p $out/{bin,include}
    install vina $out/bin/.
    install vina_split $out/bin/.
    install ../../../src/lib/vina.h $out/include/.
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Molecular docking with classical scoring functions";
    homepage = "https://github.com/ccsb-scripps/AutoDock-Vina";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
