{ stdenv, lib, fetchFromGitHub, meson, ninja, gfortran, pkg-config, json-fortran, cmake }:

stdenv.mkDerivation rec {
  pname = "mctc-lib";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-3e89g0WkZU/HTBtGaLKzhsv2RTlFk/QK0OT24BGfcKQ=";
  };

  postPatch = ''
    substituteInPlace config/template.pc \
      --replace 'libdir=''${prefix}/@CMAKE_INSTALL_LIBDIR@' "libdir=@CMAKE_INSTALL_LIBDIR@" \
      --replace 'includedir=''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@' "includedir=@CMAKE_INSTALL_INCLUDEDIR@"
  '';

  nativeBuildInputs = [
    ninja
    gfortran
    pkg-config
    cmake
  ];

  buildInputs = [ json-fortran ];

  meta = with lib; {
    description = "Modular computation tool chain library";
    homepage = "https://github.com/grimme-lab/mctc-lib";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
