{ buildPythonPackage
, dftbplus
, numpy
, hatchling
, dptools
, pyprojectVersionPatchHook
}:

buildPythonPackage rec {
  inherit (dftbplus) version meta;
  pname = "dftbplus";

  src = "${dftbplus.src}/tools/pythonapi";

  pyproject = true;

  nativeBuildInputs = [
    pyprojectVersionPatchHook
  ];

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
