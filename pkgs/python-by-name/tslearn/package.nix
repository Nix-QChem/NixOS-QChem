{ buildPythonPackage
, lib
, fetchFromGitHub
, setuptools
, numpy
, scipy
, scikit-learn
, numba
, joblib
}:

buildPythonPackage (finalAttrs: {
  pname = "tslearn";
  version = "0.6.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "tslearn-team";
    repo = "tslearn";
    rev = "v${finalAttrs.version}";
    hash = "sha256-KDweUB80u+Ox54jJtNXh/Ehem4LZHsIzq3gCvA/9S7g=";
  };

  build-system = [ setuptools ];

  dependencies = [
    numpy
    scipy
    scikit-learn
    numba
    joblib
  ];

  pythonImportsCheck = [ "tslearn" ];

  meta = with lib; {
    description = "Machine learning toolkit dedicated to time-series data";
    homepage = "https://github.com/tslearn-team/tslearn";
    license = licenses.bsd2;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
})
