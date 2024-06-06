{ lib, stdenv, fetchFromGitHub, cmake, openblasCompat }:

stdenv.mkDerivation rec {
  pname = "libtensor";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "adc-connect";
    repo = "libtensor";
    rev = "v${version}";
    sha256 = "1lm8i6mq3mls7sn2vb3la1jr1nrqk23ja2s943b262vc3zpk1sxc";
  };


  # bug in the cmakeSetupHook which breaks
  # paths in expr/opt/...
  dontFixCmake = true;

  nativeBuildInputs = [ cmake ];
  buildInputs = [ openblasCompat ];

  meta = with lib; {
    description = "C++ library for tensor computations";
    platforms = platforms.unix;
    license = licenses.boost;
    maintainers = [ maintainers.markuskowa ];
  };
}
