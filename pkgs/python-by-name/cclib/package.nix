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
  version = "1.8.1b0";

  src = fetchFromGitHub {
    owner = "cclib";
    repo = pname;
    rev = "07590622dbd571c31f8b874697ce024908345d9a";
    hash = "sha256-w9o2kBRS6UqTn4HmBSCvx008uUBzYFRaFk0pfY2nM7I=";
  };

  pyproject = true;

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
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

  checkInputs = [ pytestCheckHook ];

  disabledTests = [
    "test_url_io"
    "test_multi_url_io"
    "test_url_seek"
    "test_ccread_url"
  ];

  meta = with lib; {
    description = "Parsers and algorithms for computational chemistry logfiles";
    homepage = "https://github.com/cclib/cclib";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    broken = isPy311;  # requires psi4, which does not build on python-3.11
  };
}
