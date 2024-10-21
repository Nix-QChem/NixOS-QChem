{ buildPythonPackage
, lib
, fetchFromGitHub
, isPy311
, setuptools
, pytestCheckHook
, numpy
, scipy
, periodictable
, pyyaml
, ase
, openbabel-bindings
, h5py
, pyscf
, iodata
, psi4
, pandas
, biopython
, pyquante
}:

buildPythonPackage rec {
  pname = "cclib";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "cclib";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-XYFVSJ11MGx2dq/yYa5jaC2XsrStZCT5WzwSCelEV3U=";
  };

  pyproject = true;

  postPatch = ''
    substituteInPlace pyproject.toml --replace-fail '"versioningit~=2.0"' ""
    sed -i "/versioningit>=/d" pyproject.toml
    sed -i '/^name =.*/a version = "${version}"' pyproject.toml
    sed -i "/dynamic =/d" pyproject.toml
    echo '__version__ = "${version}"' > cclib/_version.py
  '';

  build-system = [
    setuptools
  ];

  dependencies = [
    numpy
    scipy
    periodictable
    pyyaml
    ase
    openbabel-bindings
    h5py
    pyscf
    iodata
    psi4
    pandas
    biopython
    pyquante
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "cclib" ];

  disabledTests = [
    "test_ccread_url"
    "test_multi_url_io"
    "test_url_io"
    "test_url_seek"
    "testpopulation.py"
    "testccio.py"
  ];

  meta = with lib; {
    description = "Parsers and algorithms for computational chemistry logfiles";
    homepage = "https://github.com/cclib/cclib";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    broken = isPy311;  # requires psi4, which does not build on python-3.11
  };
}
