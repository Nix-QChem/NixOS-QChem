{ lib, stdenv, fetchFromGitHub, cmake, blas, hdf5-full } :
assert
  lib.asserts.assertMsg
  (!blas.isILP64)
  "32 bit integer BLAS implementation required.";

stdenv.mkDerivation rec {
  pname = "CheMPS2";
  version = "1.8.12";

  src = fetchFromGitHub {
    owner = "SebWouters";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-us7EzPzLrWJxLwInFVWsn1g2/OJo5rAZgIUnUpo/wXQ=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ blas hdf5-full ];

  doCheck = true;

  preCheck = ''
    export LD_LIBRARY_PATH=$PWD/CheMPS2
    export OMP_NUM_THREADS=2
  '';

  meta = with lib; {
    description = "A spin-adapted implementation of DMRG for ab initio quantum chemistry";
    homepage = "http://sebwouters.github.io/CheMPS2";
    license = licenses.gpl2;
    maintainers = [ maintainers.markuskowa ];
  };
}

