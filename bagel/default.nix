{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, python, boost, openmpi, libxc, fetchpatch
# blas/lapack implementation
# requires openblas >= 0.3.0
, mathlib
} :

let
  version = "1.1.1";

in stdenv.mkDerivation {
  name = "bagel-${version}";

  src = fetchFromGitHub {
    owner = "nubakery";
    repo = "bagel";
    rev = "v${version}";
    sha256 = "1yxkhqd9rng02g3zd7c1b32ish1b0gkrvfij58v5qrd8yaiy6pyy";
  };

  nativeBuildInputs = [ autoconf automake libtool ];
  buildInputs = [ python boost libxc mathlib ];

  CXXFLAGS="-DNDEBUG -O3 -mavx";
  LD_FLAGS="-lopenblas";

  configureFlags = [ "--disable-scalapack" "--disable-smith" "--with-libxc" ];
#  configureFlags = [ "--with-libxc" ];

  postPatch = ''
    # Fixed upstream
    sed -i '/using namespace std;/i\#include <string.h>' src/util/math/algo.cc
  '';

  preConfigure = ''
    ./autogen.sh
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Brilliantly Advanced General Electronic-structure Library";
    homepage = http://www.shiozaki.northwestern.edu/bagel.php;
    license = with licenses; gpl3;
    platforms = platforms.linux;
  };
}

