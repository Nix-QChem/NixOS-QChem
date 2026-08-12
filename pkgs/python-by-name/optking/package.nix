{ buildPythonPackage
, lib
, fetchFromGitHub
, setuptools
, numpy
, qcelemental
, qcengine
, msgpack
, isPy311
}:

buildPythonPackage rec {
  pname = "optking";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "psi-rking";
    repo = "optking";
    rev = version;
    hash = "sha256-l+l7uw6OUIpqV3EqqdZzqoibd1C+OARZlt8QTuNszbM=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  dependencies = [
    numpy
    qcelemental
    qcengine
    msgpack
  ];

  doCheck = false; # Requires pytest-pep8 which is missing in nixpkgs
  pythonImportsCheck = [ "optking" ];

  meta = with lib; {
    description = "Python version of the Psi4 geometry optimization program by R.A. King ";
    homepage = "https://github.com/psi-rking/optking";
    license = licenses.bsd3;
    platforms = platforms.unix;
    broken = isPy311; # django is currently broken on python311
  };
}
