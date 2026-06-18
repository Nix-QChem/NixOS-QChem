{ lib, buildPythonPackage, fetchFromGitLab, numpy, protobuf, setuptools } :

buildPythonPackage rec {
  pname = "pyQDng";
  version = "0.10.0";

  src = fetchFromGitLab {
    domain = "gitlab.fysik.su.se";
    owner = "markus.kowalewski";
    repo = "pyqdng";
    rev = "v${version}";
    sha256 = "sha256-dMUcT5Kt0clVYTOZReamMPS7bpIvYJjJUTJZA0CCkow=";
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
