{ stdenv, fetchFromGitHub, cmake, openblasCompat, hdf5 } :

stdenv.mkDerivation rec {
  name = "CheMPS2";
  version = "1.8.9";

  src = fetchFromGitHub {
    owner = "SebWouters";
    repo = name;
    rev = "v${version}";
    sha256 = "0813z3myyri11lhh18kfpg5xs7imds9dg4kmab82lpp2isymakic";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ openblasCompat hdf5 ];

  doCheck = true;

  preCheck = ''
    export LD_LIBRARY_PATH=`pwd`/CheMPS2
    export OMP_NUM_THREADS=1
  '';

  meta = with stdenv.lib; {
    description = "A spin-adapted implementation of DMRG for ab initio quantum chemistry";
    homepage = "http://sebwouters.github.io/CheMPS2";
    license = licenses.gpl2;
    maintainers = [ maintainers.markuskowa ];
  };
}

