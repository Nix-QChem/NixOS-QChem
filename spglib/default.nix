{ stdenv, fetchFromGitHub, cmake } :

stdenv.mkDerivation rec {
  pname = "spglib";
  version = "1.16.0";


  src = fetchFromGitHub {
    owner = "atztogo";
    repo = "spglib";
    rev = "v${version}";
    sha256 = "1kzc956m1pnazhz52vspqridlw72wd8x5l3dsilpdxl491aa2nws";
  };

  nativeBuildInputs = [ cmake ];

  checkTarget = "check";
  doCheck = true;

  meta = with stdenv.lib; {
    description = "C library for finding and handling crystal symmetries";
    homepage = "https://atztogo.github.io/spglib/";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}

