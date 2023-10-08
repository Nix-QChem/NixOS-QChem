{ lib
, fetchPypi
, buildPythonPackage
, pythonOlder
, numpy
, packaging
, periodictable
, scipy
, ase
, biopython
, iodata_alpha
, openbabel-bindings
, pandas
, psi4
, pyscf
}:

buildPythonPackage rec {
  pname = "cclib";
  version = "1.8";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-Eren7YGR8C+hIyDb3IMFRu4WFei0c349dm80Yiq71SE=";
  };

  propagatedBuildInputs = [
    numpy
    packaging
    periodictable
    scipy
  ];

  passthru.optional-dependencies = {
    ase = [ ase ];
    biopython = [ biopython ];
    iodata = [ iodata_alpha ];
    openbabel = [ openbabel-bindings ];
    pandas = [ pandas ];
    psi4 = [ psi4 ];
    pyscf = [ pyscf ];
  };

  nativeCheckInputs = lib.flatten (lib.attrValues passthru.optional-dependencies);

  meta = with lib; {
    description = "Library for parsing and interpreting the results of computational chemistry packages";
    homepage = "https://cclib.github.io/";
    changelog = "https://github.com/cclib/cclib/releases/tag/${version}";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
  };
}
