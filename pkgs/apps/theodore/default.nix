{ lib, fetchFromGitHub, buildPythonPackage
, pytest-runner
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
  version = "3.0";

  src = fetchFromGitHub {
    owner = "felixplasser";
    repo = "theodore-qc";
    rev = "v${version}";
    sha256 = "sha256-HESkOnSWr3kCfCI1reFNx1pLf/nKJgfcfGQxVs5GeCE=";
    # deepClone = true;
  };

  patches = [
    ./fix-imports.patch
    ./setuppy.patch
  ];

  checkInputs = [
    pytest pytest-runner
  ];

  propagatedBuildInputs = [
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
    broken = true;
    description = "Parallel Python program package for post-processing wave function data from output files of quantum chemical programs";
    homepage = "http://orbkit.github.io/";
    license = licenses.lgpl3Only;
    maintainers = [ maintainers.markuskowa ];
  };
}
