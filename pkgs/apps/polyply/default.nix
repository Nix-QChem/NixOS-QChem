{ lib, buildPythonPackage, fetchFromGitHub, numpy, scipy, vermouth, pbr
, tqdm, numba, pytestCheckHook }:

buildPythonPackage rec {
  pname = "polyply";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "marrink-lab";
    repo = "polyply_1.0";
    rev = "v${version}";
    hash = "sha256-JJDIsWCmjf6FxJqzHZC6scPr7iaFgOJYHfZaBnD3xUk=";
  };

  postPatch = ''
    substituteInPlace setup.cfg \
      --replace "decorator == 4.4.2" ""
  '';

  propagatedBuildInputs = [
    numpy
    scipy
    vermouth
    tqdm
    numba
    pbr
  ];

  preConfigure = "export PBR_VERSION=${version}";
  format = "pyproject";

  checkInputs = [ pytestCheckHook ];
  disabledTests = [ "test_integration_protein" ];
  pythonImportsCheck = [ "polyply" ];

  meta = with lib; {
    description = "Generate input parameters and coordinates for atomistic and coarse-grained simulations of polymers, ssDNA, and carbohydrates";
    homepage = "https://github.com/marrink-lab/polyply_1.0";
    maintainers =  [ maintainers.sheepforce ];
    license = [ licenses.asl20 ];
  };
}

