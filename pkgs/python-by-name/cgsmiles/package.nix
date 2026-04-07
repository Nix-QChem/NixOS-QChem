{ buildPythonPackage
, python
, lib
, fetchFromGitHub
, setuptools
, pbr
, networkx
, pysmiles
, numpy
, pytestCheckHook
, rdkit
}:

buildPythonPackage (finalAttrs: {
  pname = "cgsmiles";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "gruenewald-lab";
    repo = "CGsmiles";
    rev = "v${finalAttrs.version}";
    hash = "sha256-wDHT2rnsS1uWDpNaGJUXNYOkMepk453pl0uQGjBOuPU=";
  };

  pyproject = true;

  preConfigure = "export PBR_VERSION=${finalAttrs.version}";

  build-system = [
    setuptools
  ];

  dependencies = [
    pbr
    networkx
    pysmiles
    numpy
  ];

  nativeCheckInputs = [
    pytestCheckHook
    rdkit
  ];

  doCheck = true;

  pythonImportsCheck = [ "cgsmiles" ];

  meta = with lib; {
    description = "Coarse-Grained SMILES (CGsmiles), a versatile line notation for molecular representations across multiple resolutions";
    homepage = "https://github.com/gruenewald-lab/CGsmiles";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
