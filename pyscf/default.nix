{ stdenv, buildPythonPackage, fetchFromGitHub
, cmake, numpy, scipy, h5py, libcint, libxc
} :

let
  version = "1.6.1";

in buildPythonPackage {
  pname = "pyscf";
  version = version;

  src = fetchFromGitHub {
    owner = "pyscf";
    repo = "pyscf";
    rev = "v${version}";
    sha256 = "12mylvc3s5pc9y6d8phxa1nqkbhjyrpd837k1skqrrv1s9888xnr";
  };

  nativeBuildInputs = [ cmake ];
  propagatedBuildInputs = [ numpy scipy h5py ];
  buildInputs = [ libcint libxc ];

  PYSCF_INC_DIR="${libcint}:${libxc}";

  doCheck = true;

  meta = with stdenv.lib; {
    description = "Python-based simulations of chemistry framework";
    homepage = https://pyscf.github.io/;
    license = licenses.apl20;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}
