{ buildPythonPackage
, fetchFromGitHub
, lib
, setuptools
, cython
, numpy
, scipy
, pyparsing
, astunparse
, zlib
}:

buildPythonPackage rec {
  pname = "mdtraj";
  version = "1.9.9";

  src = fetchFromGitHub {
    owner = "mdtraj";
    repo = pname;
    rev = version;
    hash = "sha256-2Jg6DyVJlRBLD/6hMtcsrAdxKF5RkpUuhAQm/lqVGeE=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "oldest-supported-numpy" "numpy" \
      --replace "Cython~=0.29.36" "Cython"
  '';

  format = "pyproject";

  buildInputs = [ zlib ];

  propagatedBuildInputs = [
    setuptools
    cython
    numpy
    pyparsing
    astunparse
    scipy
  ];

  pythonImportsCheck = [ "mdtraj" ];

  meta = with lib; {
    description = "Open library for the analysis of molecular dynamics trajectories";
    homepage = "https://github.com/mdtraj/mdtraj";
    license = licenses.lgpl21Plus;
    maintainers = [ maintainers.sheepforce ];
  };
}
