{ lib, stdenv, fetchFromGitHub, cmake
, blas, python
} :
let
  version = "4.1.3";

in stdenv.mkDerivation {
  pname = "libcint";
  inherit version;

  src = fetchFromGitHub {
    owner = "sunqm";
    repo = "libcint";
    rev = "v${version}";
    sha256 = "0dk0100r0nw25xkslvnbn52jdqz9j27v93gjj4fmxsz67kykmc74";
  };

  nativeBuildInputs = [ cmake python python.pkgs.numpy ];
  buildInputs = [ blas ];

  doCheck = true;

  # somehow gets /nix/store/.. twice
  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX:PATH=/"
    "-DENABLE_TEST=0"
    "-DWITH_RANGE_COULOMB=1"
    "-DI8=0"
  ];

  meta = with lib; {
    description = "Open source library for analytical Gaussian integrals";
    homepage = https://github.com/sunqm/libcint;
    license = licenses.bsd2;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}
