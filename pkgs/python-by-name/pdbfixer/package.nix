{ buildPythonPackage
, lib
, fetchFromGitHub
, openmm
, numpy
, setuptools
, legacy-cgi
}:

buildPythonPackage rec {
  pname = "pdbfixer";
  version = "1.12";

  src = fetchFromGitHub {
    owner = "openmm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-X2P5cWmdvAjY9dMFB+R21advkdYizR8PmevMPR0RR0o=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  dependencies = [
    openmm
    numpy
    legacy-cgi
  ];

  pythonImportsCheck = [ "pdbfixer" ];
  doCheck = false; # All tests want to fetch a PDB from rcsb.org

  meta = with lib; {
    inherit (openmm.meta) license;
    description = "Toolkit for molecular simulation using high performance GPU code";
    homepage = "https://openmm.org/";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
