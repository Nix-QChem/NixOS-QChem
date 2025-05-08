{ buildPythonPackage
, lib
, dftbplus
, numpy
, hatchling
, dptools
}:

buildPythonPackage rec {
  inherit (dftbplus) version meta;
  pname = "dftbplus";

  src = "${dftbplus.src}/tools/pythonapi";

  pyproject = true;

  buildInputs = [
    dftbplus
  ];

  dependencies = [
    hatchling
    numpy
    dptools
  ];

  pythonImportsCheck = [ "dftbplus" ];
}
