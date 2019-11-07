{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, doxygen, texlive, python, perl, gmpxx, mpfr, boost
, eigen
, cfg ? []
} :

let
  version = "2.6.0";

in stdenv.mkDerivation {
  name = "libint-${version}";

  src = fetchFromGitHub {
    owner = "evaleev";
    repo = "libint";
    rev = "v${version}";
    sha256 = "0pbc2j928jyffhdp4x5bkw68mqmx610qqhnb223vdzr0n2yj5y19";
  };

  postPatch = ''
    find -name Makefile -exec sed -i 's:/bin/rm:rm:' \{} \;
  '';

  nativeBuildInputs = [ autoconf automake libtool doxygen texlive.combined.scheme-small mpfr ];
  buildInputs = [ python perl gmpxx boost ];

  enableParallelBuilding = true;

  doCheck = true;

  configureFlags = cfg;

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

