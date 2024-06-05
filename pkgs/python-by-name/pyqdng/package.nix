{ lib, buildPythonPackage, fetchFromGitLab, numpy, protobuf } :

buildPythonPackage rec {
  pname = "pyQDng";
  version = "0.9.1";

  src = fetchFromGitLab {
    domain = "gitlab.fysik.su.se";
    owner = "markus.kowalewski";
    repo = "pyqdng";
    rev = "v${version}";
    sha256 = "sha256-hdmgULSyWnHBxuLXsDgGu1CqjEmm7AWEhx7jgm8g7qw=";
  };

  propagatedBuildInputs = [ numpy protobuf ];

  meta = with lib; {
    description = "Python package for handling QDng binary files";
    homepage = "https://gitlab.fysik.su.se/markus.kowalewski/pyqdng";
    maintainers = [ maintainers.markuskowa ];
    license = [ licenses.gpl2Only ];
    platforms = platforms.all;
  };
}
