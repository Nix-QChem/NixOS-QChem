{ lib
, buildPythonPackage
, fetchFromGitHub
, numpy
, scipy
, vermouth
, pbr
, tqdm
, numba
, pysmiles
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "polyply";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "marrink-lab";
    repo = "polyply_1.0";
    rev = "v${version}";
    hash = "sha256-Mzmce3noziwi2qsoUmbzf3va7gdDjMdZRToeFb0S+oc=";
  };

  postPatch = ''
    substituteInPlace setup.cfg \
      --replace "decorator == 4.4.2" ""
  '';

  dependencies = [
    numpy
    scipy
    vermouth
    tqdm
    numba
    pbr
    pysmiles
  ];

  preConfigure = "export PBR_VERSION=${version}";
  pyproject = true;

  checkInputs = [ pytestCheckHook ];
  disabledTests = [ "test_integration_protein" ];
  pythonImportsCheck = [ "polyply" ];

  meta = with lib; {
    description = "Generate input parameters and coordinates for atomistic and coarse-grained simulations of polymers, ssDNA, and carbohydrates";
    homepage = "https://github.com/marrink-lab/polyply_1.0";
    maintainers = [ maintainers.sheepforce ];
    license = [ licenses.asl20 ];
  };
}

