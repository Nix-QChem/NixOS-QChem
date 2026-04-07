{ buildPythonPackage
, python
, lib
, fetchFromGitHub
, setuptools
, pbr
, networkx
, pytestCheckHook
, hypothesis
}:

buildPythonPackage (finalAttrs: {
  pname = "pysmiles";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "pckroon";
    repo = "pysmiles";
    rev = "v${finalAttrs.version}";
    hash = "sha256-80i9EhXbT/dV+CJ8fLo606sVvAR+VtdP/BXRQlKkMWA=";
  };

  pyproject = true;

  preConfigure = "export PBR_VERSION=${finalAttrs.version}";

  build-system = [
    setuptools
  ];

  dependencies = [
    pbr
    networkx
  ];

  nativeCheckInputs = [
    pytestCheckHook
    hypothesis
  ];

  doCheck = true;

  postInstall = ''
    cp pysmiles/PTE.json $out/${python.sitePackages}/pysmiles/.
  '';

  pythonImportsCheck = [ "pysmiles" ];

  meta = with lib; {
    description = " lightweight python-only library for reading and writing SMILES strings";
    homepage = "https://github.com/pckroon/pysmiles";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
