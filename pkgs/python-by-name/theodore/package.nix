{ lib, fetchFromGitHub, buildPythonPackage, isPy311
, setuptools
, pytest
, pycolt
, cclib
, numpy
, orbkit
, matplotlib
, openbabel
, openbabel-bindings
}:

buildPythonPackage rec {
  pname = "theodore";
  version = "3.1.1";

  src = fetchFromGitHub {
    owner = "felixplasser";
    repo = "theodore-qc";
    rev = "v${version}";
    hash = "sha256-z3li/X7uQYRqS2GkAGa3sKdQ/1KdOHi0aWhO/HaItH4=";
  };

  patches = [
    ./fix-imports.patch
    ./setuppy.patch
  ];

  postPatch = ''
    substituteInPlace setup.py --replace "'pytest-runner', " ""
  '';

  checkInputs = [
    pytest
  ];

  dependencies = [
    setuptools
    pycolt
    cclib
    numpy
    orbkit
    matplotlib
    openbabel
    openbabel-bindings
  ];

  doCheck = true;

  meta = with lib; {
    description = "Parallel Python program package for post-processing wave function data from output files of quantum chemical programs";
    homepage = "https://github.com/felixplasser/theodore-qc";
    license = licenses.lgpl3Only;
    maintainers = [ maintainers.markuskowa ];
    broken = isPy311; # theodore is not broken, but pycolt is.
  };
}
