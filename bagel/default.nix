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
    rev = "v${version}";
    sha256 = "1yxkhqd9rng02g3zd7c1b32ish1b0gkrvfij58v5qrd8yaiy6pyy";
  };

  nativeBuildInputs = [ autoconf automake libtool ];
  buildInputs = [ python boost openmpi libxc openblas scalapack ];

  CXXFLAGS="-DNDEBUG";

  configureFlags = [ "--with-mpi=openmpi" "--with-libxc" ];

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with stdenv.lib; {
    description = ""Brilliantly Advanced General Electronic-structure Library;
    homepage = http://www.shiozaki.northwestern.edu/bagel.php;
    license = with licenses; gpl3;
    platforms = platforms.linux;
  };
}

