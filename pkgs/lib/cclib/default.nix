{ lib, fetchPypi, buildPythonPackage
, packaging, numpy, scipy, periodictable, pyqt4
}:

buildPythonPackage rec {
  pname = "cclib";
  version = "1.7.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-uxa0IjgvR+rWX5K2zS2BJAlDbIMG4MWwSQVjN6Ed/Do=";
  };

  propagatedBuildInputs = [
    numpy
    scipy
    packaging
    periodictable
    pyqt4
  ];

  # fails because of a pyqt4 import test
  doCheck = false;

  meta = with lib; {
    description = "Library for parsing and interpreting the results of computational chemistry packages";
    homepage = "https://cclib.github.io/";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    broken = true;
  };
}
