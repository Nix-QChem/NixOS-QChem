{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools-scm
, pytest
}:

buildPythonPackage rec {
  pname = "pytest-forked";
  version = "1.7.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-forked";
    rev = "v${version}";
    hash = "sha256-RPuJAukcfVjZHZQ+a/bxADhY3BJKmSe3S/6eHUG3kYQ=";
  };

  build-system = [
    setuptools-scm
  ];

  dependencies = [
    pytest
  ];

  # Tests require pytest-forked to be installed first
  doCheck = false;

  meta = {
    description = "Forked subprocess test execution for pytest (1.7.5, works with Python 3.14)";
    homepage = "https://github.com/pytest-dev/pytest-forked";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
