{ buildPythonPackage
, lib
, dftbplus
, numpy
, hatchling
}:

buildPythonPackage rec {
  inherit (dftbplus) version meta;
  pname = "dptools";

  src = "${dftbplus.src}/tools/dptools";

  pyproject = true;

  buildInputs = [
    dftbplus
  ];

  dependencies = [
    hatchling
    numpy
  ];

  pythonImportsCheck = [ "dptools" ];
}
