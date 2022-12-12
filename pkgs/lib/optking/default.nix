{ buildPythonPackage
, lib
, fetchFromGitHub
, numpy
, qcelemental
, qcengine
, msgpack
}:

buildPythonPackage rec {
  pname = "optking";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "psi-rking";
    repo = "optking";
    rev = version;
    hash = "sha256-d/C7h6cwL2bQUGggpGeu9yPkJnD37U1KWoOZNvI0W4k=";
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
