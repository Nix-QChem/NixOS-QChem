{ buildPythonPackage
, lib
, pythonAtLeast
, fetchFromGitHub
, numpy
, qcelemental
, qcengine
, msgpack
}:

buildPythonPackage rec {
  pname = "optking";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "psi-rking";
    repo = "optking";
    rev = version;
    hash = "sha256-vHoxmJAfuGHiqXIOb935X1ezTT6AYmTWnLeJZSiB1KY=";
  };

  propagatedBuildInputs = [
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
  };
}
