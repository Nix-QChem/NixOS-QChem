{ buildPythonPackage, lib, fetchFromGitHub, openmm, numpy, setuptools } :

buildPythonPackage rec {
  pname = "pdbfixer";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "openmm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-XrGP+hYi2+5Nw9nPJkmsCfiNO6Q6kENhG3LUjxEzVD8=";
  };

  propagatedBuildInputs = [
    openmm
    numpy
    setuptools
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
