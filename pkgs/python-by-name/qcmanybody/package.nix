{ buildPythonPackage
, lib
, fetchFromGitHub
, setuptools
, setuptools-scm
, numpy
, pydantic
, qcelemental
, zstandard
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "QCManyBody";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "MolSSI";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-4/DIR9Y//CUlZQTxLO4L8DSju07gJ0iZobmpfIus2Cw=";
  };

  pyproject = true;
  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    numpy
    qcelemental
    pydantic
    zstandard
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  doCheck = true;

  meta = with lib; {
    description = "Intermolecular many-body expansion with QCArchive integration";
    homepage = "https://github.com/MolSSI/QCManyBody";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
