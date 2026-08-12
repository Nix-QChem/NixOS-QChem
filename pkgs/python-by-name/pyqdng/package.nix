{ lib, buildPythonPackage, fetchFromGitLab, numpy, protobuf, setuptools } :

buildPythonPackage rec {
  pname = "pyQDng";
  version = "0.10.1";

  src = fetchFromGitLab {
    domain = "gitlab.fysik.su.se";
    owner = "markus.kowalewski";
    repo = "pyqdng";
    rev = "v${version}";
    sha256 = "sha256-t/BCExkW2uzhQ7mkr/GR0F5BsKz/QNYfo2sj1VfM/Kk=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  propagatedBuildInputs = [ numpy protobuf ];

  doCheck = true;

  checkPhase = ''
    python ./tests.py
  '';

  meta = with lib; {
    description = "Python package for handling QDng binary files";
    homepage = "https://gitlab.fysik.su.se/markus.kowalewski/pyqdng";
    maintainers = [ maintainers.markuskowa ];
    license = [ licenses.gpl2Only ];
    platforms = platforms.all;
  };
}
