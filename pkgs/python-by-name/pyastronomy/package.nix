{ buildPythonPackage
, fetchFromGitHub
, lib
, numpy
, matplotlib
, quantities
, numpydoc
, mock
, six
, sphinx
, nbsphinx
, scipy
, bidict
, docutils
, ipython
, mendeleev
}:

buildPythonPackage rec {
  pname = "PyAstronomy";
  version = "0.22.0";

  src = with lib.versions; fetchFromGitHub {
    owner = "sczesla";
    repo = pname;
    rev = "v_${major version}-${minor version}-${patch version}";
    hash = "sha256-eZorxlBHRE6NZH4elF0bRDNo8NY8DFij55uctv+YrK4=";
  };

  propagatedBuildInputs = [
    numpy
    matplotlib
    quantities
    numpydoc
    mock
    six
    sphinx
    nbsphinx
    scipy
    bidict
    docutils
    ipython
    mendeleev
  ];

  configureFlags = [ "--with-ext" ];

  # Deprecated setuptools tests
  doCheck = false;

  pythonImportsCheck = [ "PyAstronomy" ];

  meta = with lib; {
    description = "A collection of astronomy-related routines in Python";
    homepage = "https://github.com/sczesla/PyAstronomy";
    license = licenses.mit;
    maintainers = [ maintainers.sheepforce ];
  };
}
