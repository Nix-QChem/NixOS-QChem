{ lib, fetchurl, buildPythonPackage, gcc, python
, numpy, cython, scipy, matplotlib, packaging
, pytest, pytest-rerunfailures
} :

buildPythonPackage rec {
  pname = "qutip";
  version = "4.6.2";

  src = fetchurl {
    url = "https://github.com/qutip/qutip/archive/refs/tags/v${version}.tar.gz";
    sha256 = "127mcq81y8nizrl6y7jbd01lsgnv6grl83pr3xrvc5z4g8qwwp8b";
  };

  patches = [
    ./requirements.patch
  ];

  buildInputs = [
    gcc
  ];

  buildPhase = ''
    ${python.interpreter} setup.py bdist_wheel --with-openmp
  '';

  propagatedBuildInputs = [
    packaging
    numpy
    cython
    scipy
    matplotlib
  ];

  doCheck = true;

  checkInputs = [
    pytest
    pytest-rerunfailures
  ];

  # - QuTiP tries to access the home directory to create an rc file for us.
  # This of course fails and therefore, we provide a writable temp dir as HOME.
  # - We need to go to another directory to run the tests from there.
  # This is due to the Cython-compiled modules not being in the correct location
  # of the source tree.
  # - For running tests, see:
  # https://qutip.org/docs/latest/installation.html#verifying-the-installation
  checkPhase = ''
    export HOME=$(mktemp -d)
    mkdir -p test && cd test
    ${python.interpreter} -c "import qutip.testing; qutip.testing.run()"
  '';

  meta = with lib; {
    description = "Open-source software for simulating the dynamics of closed and open quantum systems";
    homepage = "https://qutip.org/";
    license = licenses.bsd3;
    maintainers = [ maintainers.fabiangd ];
  };
}
