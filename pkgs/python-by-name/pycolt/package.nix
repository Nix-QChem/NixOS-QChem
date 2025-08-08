{ lib, fetchPypi, buildPythonPackage
, isPy311
, bump2version
, wheel
, watchdog
, flake8
, tox
, coverage
, sphinx
, twine
, setuptools
, numpy
}:

buildPythonPackage rec {
  pname = "pycolt";
  version = "0.6.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-C68jQWDmVVZHcgfK0JAAvzYGlEcN4coqrUBlqlae9Xo=";
  };

  postPatch = ''
    substituteInPlace setup.py --replace "'pytest-runner', " ""
  '';

  pyproject = true;
  build-system = [ setuptools ];

  dependencies = [
    numpy
    bump2version
    wheel
    watchdog
    flake8
    tox
    coverage
    sphinx
    twine
  ];

  doCheck = false;

  meta = with lib; {
    description = "Simple, extensible tool to create out of the box input files and commandline interfaces";
    homepage = "https://github.com/mfsjmenger/colt";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    broken = isPy311;
  };
}
