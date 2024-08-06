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
  version = "0.2.1";
  disabled = pythonAtLeast "3.12";

  src = fetchFromGitHub {
    owner = "psi-rking";
    repo = "optking";
    rev = "3025f85c47df308c4482341129db9ad5ebc82c6a"; # Tag keeps moving
    hash = "sha256-mXLBsc4PQjeTjUg0nzf9PI0FF81y77yCJ5l+g47uoD8=";
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
