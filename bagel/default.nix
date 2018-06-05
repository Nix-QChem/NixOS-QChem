{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, python, boost, openmpi, libxc, openblas, scalapack
} :

let
  version = "1.1.1";

in stdenv.mkDerivation {
  name = "bagel-${version}";

  src = fetchFromGitHub {
    owner = "nubakery";
    repo = "bagel";
    rev = "dec9c1d1655b43239d89eec3928aff42774c8a77";
    sha256 = "1yxkhqd9rng02g3zd7c1b32ish1b0gkrvfij58v5qrd8yaiy6pyy";
  };

  nativeBuildInputs = [ autoconf automake libtool ];
  buildInputs = [ python boost openmpi libxc openblas scalapack ];

  CXXFLAGS="-DNDEBUG";
  LD_FLAGS="";

  configureFlags = [ "--with-mpi=openmpi" "--with-libxc" ];

  postPatch = ''
    sed -i '/using namespace std;/i\#include <string.h>' src/util/math/algo.cc
  '';

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with stdenv.lib; {
    description = "Brilliantly Advanced General Electronic-structure Library";
    homepage = http://www.shiozaki.northwestern.edu/bagel.php;
    license = with licenses; gpl3;
    platforms = platforms.linux;
  };
}

