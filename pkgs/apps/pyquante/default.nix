{ lib
, fetchFromGitHub
, buildPythonPackage
, python
, setuptools
, numpy
, cython
}:

buildPythonPackage rec {
  pname = "pyquante2";
  version = "unstable-2024-01-23";

  src = fetchFromGitHub {
    owner = "rpmuller";
    repo = pname;
    rev = "fa02f54318cd704515698808a2eacaea565d2274";
    hash = "sha256-pRNPu5ZnuWaSF4KCCj4QoBIsU/FlHuMWvBJ1QD/nLuQ=";
  };

  pyproject = true;

  nativeBuildInputs = [ setuptools cython ];

  propagatedBuildInputs = [ numpy ];

  # C-Extensions are not automatically installed and are copied manually
  postInstall = ''
    cp -r build/*/pyquante2/cints $out/${python.sitePackages}/pyquante2/.
    cp -r build/*/pyquante2/cbecke* $out/${python.sitePackages}/pyquante2/.
  '';

  pythnonImportsCheck = [ "pyquante2" "pyquante2.cints.one" ];

  meta = with lib; {
    description = "Open-source suite of programs for developing quantum chemistry methods";
    homepage = "https://github.com/rpmuller/pyquante2";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
  };
}
