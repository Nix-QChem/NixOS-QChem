{ stdenv, fetchFromGitHub, cmake } :

stdenv.mkDerivation rec {
  name = "spglib";
  version = "1.14.1";


  src = fetchFromGitHub {
    owner = "atztogo";
    repo = "spglib";
    rev = "v${version}";
    sha256 = "16h4yaap188p00fkmpapv6ws19h9rjch4xwd70w6wbdpiy582wsw";
  };

  nativeBuildInputs = [ cmake ];

  doCheck = true;

  meta = with stdenv.lib; {
    description = "C library for finding and handling crystal symmetries";
    homepage = "https://atztogo.github.io/spglib/";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}

