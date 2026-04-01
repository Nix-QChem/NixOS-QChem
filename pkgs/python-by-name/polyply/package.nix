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
, cgsmiles
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
      --replace-fail "decorator == 4.4.2" ""

    # Handle both NetworkX node-link key conventions ("links" and "edges").
    substituteInPlace polyply/src/simple_seq_parsers.py \
      --replace-fail "json_graph.node_link_graph(data)" "json_graph.node_link_graph(data, edges=\"links\" if \"links\" in data else \"edges\")"

    substituteInPlace polyply/tests/test_gen_seq.py \
      --replace-fail "json_graph.node_link_graph(js_graph)" "json_graph.node_link_graph(js_graph, edges=\"links\" if \"links\" in js_graph else \"edges\")"
  '';

  dependencies = [
    numpy
    scipy
    vermouth
    tqdm
    numba
    pbr
    pysmiles
    cgsmiles
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

