{ lib
, buildPythonPackage
, fetchFromGitHub
, numpy
, scipy
, vermouth
, pbr
, tqdm
, numba
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "polyply";
  version = "unstable-15-08-2023";

  src = fetchFromGitHub {
    owner = "marrink-lab";
    repo = "polyply_1.0";
    rev = "1ecd4d585eb00810e547deff63a1debebe071b7e";
    hash = "sha256-115wCHdthG5kLIukwiOeO1ld7S4h/CFOVRQq92wtiv8=";
  };

  postPatch = ''
    substituteInPlace setup.cfg \
      --replace "decorator == 4.4.2" "" \
      --replace 'networkx ~= 2.0' 'networkx'
  '';

  propagatedBuildInputs = [
    numpy
    scipy
    vermouth
    tqdm
    numba
    pbr
  ];

  preConfigure = "export PBR_VERSION=1.5.0";
  format = "pyproject";

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

