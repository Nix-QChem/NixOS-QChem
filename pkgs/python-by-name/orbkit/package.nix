{ lib, fetchFromGitHub, buildPythonPackage
, cython
, numpy
, scipy
, matplotlib
, h5py
, scikitimage
}:

buildPythonPackage rec {
  pname = "orbkit";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "orbkit";
    repo = "orbkit";
    rev = "dcfcc2028b8459a0d8647243cc8e1c30384aa829";
    sha256 = "sha256-Sg/fl9ts9m8M2uDHtFAZnI7sHd7QpY9wln+9R/xedko=";
  };

  propagatedBuildInputs = [
    cython
    numpy
    scipy
    matplotlib
    h5py
    scikitimage
  ];

  # fails because of a pyqt4 import test
  doCheck = false;

  meta = with lib; {
    description = "Parallel Python program package for post-processing wave function data from output files of quantum chemical programs";
    homepage = "http://orbkit.github.io/";
    license = licenses.lgpl3Only;
    maintainers = [ maintainers.markuskowa ];
  };
}
