{ buildPythonPackage
, lib
, isPy311
, fetchFromGitHub
, setuptools
, setuptools-scm
, numpy
, pydantic
, qcelemental
, zstandard
, pytestCheckHook
, pythonRelaxDepsHook
}:

buildPythonPackage (finalAttrs: {
  pname = "QCManyBody";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "MolSSI";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-zCFWIfvVPnoaS2W7kmY2F8CWlrvPzCUoGfn2YFxGz/8=";
  };

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  pythonRelaxDeps = [ "qcelemental" ];

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
    broken = isPy311;
  };
})
