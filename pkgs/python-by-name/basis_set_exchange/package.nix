{ buildPythonPackage
, lib
, fetchFromGitHub
, setuptools
, setuptools-scm
, numpy
, jsonschema
, argcomplete
, regex
, unidecode
}:

buildPythonPackage rec {
  pname = "basis_set_exchange";
  version = "0.10";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "MolSSI-BSE";
    repo = "basis_set_exchange";
    rev = "v${version}";
    hash = "sha256-HuPEbZXkdwwJ1LrV1/nCmjIuVzOtUD6cvr8Xq2qIAsY=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    numpy
    jsonschema
    argcomplete
    regex
    unidecode
  ];

  pythonImportsCheck = [ "basis_set_exchange" ];

  meta = with lib; {
    description = "Basis Set Exchange";
    homepage = "https://github.com/MolSSI-BSE/basis_set_exchange";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = [ maintainers.sheepforce ];
  };
}
