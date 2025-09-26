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
  version = "3.2";

  src = fetchFromGitHub {
    owner = "felixplasser";
    repo = "theodore-qc";
    rev = "v${version}";
    hash = "sha256-WKgLlZ7X5tVPPghWsqV3I6qAmXU7zxEhd7JJpSRVOWE=";
  };

  patches = [
    ./fix-imports.patch
    ./setuppy.patch
  ];

  pyproject = true;
  build-system = [ setuptools ];

  postPatch = ''
    substituteInPlace setup.py --replace "'pytest-runner', " ""
  '';

  checkInputs = [
    pytest
  ];

  dependencies = [
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
