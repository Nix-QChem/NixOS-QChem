{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools,
  numpy,
  scipy,
  mypy-extensions,
  cycler,
  fonttools,
  h5py,
  kiwisolver,
  matplotlib,
  pyyaml,
  python-dateutil,
  pillow,
} :

buildPythonPackage rec {
  pname = "autocas";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "qcscine";
    repo = "autocas";
    tag = version;
    hash = "sha256-QBx6TH71o/tX/k1br1yA4zAQQQOPz6eR8R5Ilm5oe7U=";
  };

  patches = [ ./relax-versions.patch ];

  pyproject = true;
  build-system = [ setuptools ];

  dependencies = [
    numpy
    scipy
    mypy-extensions
    cycler
    fonttools
    h5py
    kiwisolver
    matplotlib
    pyyaml
    python-dateutil
    pillow
  ];

  meta = {
    description = "Automate active-orbital-space selection step in MCSCF calculations";
    homepage = "https://scine.ethz.ch/download/autocas";
    maintainers = [ lib.maintainers.markuskowa ];
    license = lib.licenses.bsd3;
  };
}



