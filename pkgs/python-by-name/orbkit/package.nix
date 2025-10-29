{ lib, fetchFromGitHub, buildPythonPackage
, setuptools
, cython
, numpy
, scipy
, matplotlib
, h5py
, scikit-image
, isPy311
}:

buildPythonPackage {
  pname = "orbkit";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "orbkit";
    repo = "orbkit";
    rev = "dcfcc2028b8459a0d8647243cc8e1c30384aa829";
    sha256 = "sha256-Sg/fl9ts9m8M2uDHtFAZnI7sHd7QpY9wln+9R/xedko=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  propagatedBuildInputs = [
    cython
    numpy
    scipy
    matplotlib
    h5py
    scikit-image
  ];

  # fails because of a pyqt4 import test
  doCheck = false;

  meta = with lib; {
    description = "Parallel Python program package for post-processing wave function data from output files of quantum chemical programs";
    homepage = "http://orbkit.github.io/";
    license = licenses.lgpl3Only;
    maintainers = [ maintainers.markuskowa ];
    broken = isPy311;
  };
}
