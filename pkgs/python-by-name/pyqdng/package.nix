{ lib, buildPythonPackage, fetchFromGitLab, numpy, protobuf, setuptools } :

buildPythonPackage rec {
  pname = "pyQDng";
  version = "0.9.2";

  src = fetchFromGitLab {
    domain = "gitlab.fysik.su.se";
    owner = "markus.kowalewski";
    repo = "pyqdng";
    rev = "v${version}";
    sha256 = "sha256-P7iLFt6I2dTVoRK4Blvx/hnQW7Vcn9EZu5e65DXutqE=";
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
