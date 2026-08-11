{ lib, fetchFromGitHub, buildPythonPackage, isPy311
, setuptools
, pytest
, pycolt
, cclib
, numpy
, orbkit
, matplotlib
, openbabel
}:

buildPythonPackage rec {
  pname = "theodore";
  version = "3.2.1";

  src = fetchFromGitHub {
    owner = "felixplasser";
    repo = "theodore-qc";
    rev = "v${version}";
    hash = "sha256-vzfqHWnuJsZqknGxC4PF/ppNAbDVy9JdOEWnC3zz/rk=";
  };

  patches = [
    ./fix-imports.patch
    ./setuppy.patch
  ];

  pyproject = true;
  build-system = [ setuptools ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail "'pytest-runner', " "" \
      --replace-fail "version='3.0_alpha'" "version='${version}'"
  '';

  checkInputs = [
    pytest
  ];

  dontCheckRuntimeDeps = true;

  dependencies = [
    pycolt
    cclib
    numpy
    orbkit
    matplotlib
    openbabel
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
