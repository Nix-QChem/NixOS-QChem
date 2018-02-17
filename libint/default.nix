{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, doxygen, texlive, python, perl, gmpxx, mpfr, boost
} :

let
  version = "2.4.2";

in stdenv.mkDerivation {
  name = "XPKG-${version}";

  src = fetchFromGitHub {
    owner = "evaleev";
    repo = "libint";
    rev = "v${version}";
    sha256 = "0lpfri0gw0nb9khzm9ppgzlh4z7sl3xrx7hyql0dvz9rc7kh96w7";
  };

  nativeBuildInputs = [ autoconf automake libtool doxygen texlive.combined.scheme-small mpfr ];
  buildInputs = [ python perl gmpxx boost ];

  enableParallelBuilding = true;

  doCheck = true;

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with stdenv.lib; {
    description = "Library for the evaluation of molecular integrals of many-body operators over Gaussian functions";
    homepage = https://github.com/evaleev/libint;
    license = licenses.lgpl3;
    platforms = platforms.linux;
  };
}

