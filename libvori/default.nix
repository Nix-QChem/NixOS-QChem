{ stdenv, lib, fetchurl, cmake }:

stdenv.mkDerivation rec {
  pname = "libvori";
  version = "201229";

  nativeBuildInputs = [ cmake ];

  # Original server is misconfigured and messes up the file compression.
  src = fetchurl {
    url = "https://www.cp2k.org/static/downloads/${pname}-${version}.tar.gz";
    sha256 = "0j5f4v380qxaf55zq8ksk9d5xzhiklcwp5fanx9apxs3qhzdlk9z";
  };

  meta = with lib; {
    description = "Library for Voronoi intergration of electron densities";
    license = with licenses; [ lgpl3Only ];
    homepage = "https://brehm-research.de/libvori.php";
    platforms = platforms.unix;
  };
}
