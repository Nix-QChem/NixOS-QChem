{ lib, buildPythonPackage, fetchFromGitLab
, numpy, scipy, h5py } :

buildPythonPackage {
  pname = "pyPHSPU";
  version = "2022-05-23";

  src = fetchFromGitLab {
    owner = "markus.kowalewski";
    repo = "pyphspu";
    domain = "gitlab.fysik.su.se";
    rev = "e4d64b41b6f850b19b2701409dc243af2ecbefcf";
    sha256 = "0r21vm8smc2j2bpamfl6aja8vd1s0c84mcjqvhdc96j2j6ld7a4n";
  };

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

