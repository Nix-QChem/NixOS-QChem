{ stdenv, buildPythonPackage, fetchFromGitHub
, numpy, scipy, h5py, libcint, libxc
} :

let
  version = "1.6.4";

in buildPythonPackage {
  pname = "pyscf";
  version = version;

  src = fetchFromGitHub {
    owner = "pyscf";
    repo = "pyscf";
    rev = "v${version}";
    sha256 = "0ngbpy4gc7p1wb9vlhbl7k66nsyr28nv7shj71gcwm5vb115lnwy";
  };

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
