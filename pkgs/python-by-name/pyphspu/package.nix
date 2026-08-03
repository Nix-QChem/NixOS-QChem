{ lib, buildPythonPackage, fetchFromGitLab
, numpy, scipy, h5py, setuptools } :

buildPythonPackage {
  pname = "pyPHSPU";
  version = "0.10.0";

  src = fetchFromGitLab {
    owner = "markus.kowalewski";
    repo = "pyphspu";
    domain = "gitlab.fysik.su.se";
    rev = "v0.10.0";
    hash = "sha256-t4rzuWvbyUCtdopNMUBaP7lhBJz9UVHDF1my0gND3vE=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  propagatedBuildInputs = [
    numpy
    scipy
    h5py
  ];

  preCheck = ''
    OMP_NUM_THREADS=$NIX_BUILD_CORES
  '';

  meta = with lib; {
    description = "Poly harmonic spline and partition of unity interpolation";
    homepage = "https://gitlab.fysik.su.se/markus.kowalewski/pyphspu";
    maintainers =  [maintainers.markuskowa ];
    license = [ licenses.gpl3Only ];
  };
}

