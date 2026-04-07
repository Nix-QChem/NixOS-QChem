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
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "MolSSI";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-dh8AVBKz8JvNf+xT4KyZlb7HJv2ObgNjk9PmUKpv/iw=";
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
