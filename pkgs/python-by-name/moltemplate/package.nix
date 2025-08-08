{ buildPythonPackage, lib, makeWrapper, fetchFromGitHub, numpy, setuptools }:

buildPythonPackage rec {
  pname = "moltemplate";
  version = "2.20.21";

  src = fetchFromGitHub {
    owner = "jewettaij";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-VUv5A+1lchRHRpHKTxxVYorcDB4aiyLj1Og6yLsye8U=";
  };

  # The moltemplate.sh script calls all python scripts with a explicit "PYTHON_COMMAND"
  # which is just the python interpreter found in PATH via which.
  # This breaks for 2 reasons:
  #   1) python scripts in $out/bin are wrapped so that they find python modules, and
  #      then become a bash script actually. Calling them with a python interpreter
  #      fails, of course. Also the python interpreter found in the path is not aware of
  #      all moltemplate dependencies
  #   2) at runtime there is no reason for moltemplate to have a python interpreter globally
  #      in path. The python scripts have proper shebangs, which work flawlessly
  patches = [ ./pythoncall.patch ];

  pyproject = true;
  build-system = [ setuptools ];

  nativeBuildInputs = [ makeWrapper ];

  # Moltemplate actually requires setuptools at runtime to find files (the pkg_resources module)
  # and unfortunately it really needs to be a propagatedBuildInput
  propagatedBuildInputs = [ numpy ];

  doCheck = false; # There are no checks
  pythonImportsCheck = [ "moltemplate" ];

  meta = with lib; {
    homepage = "https://www.moltemplate.org/";
    description = "A general cross-platform tool for preparing simulations of molecules and complex molecular assemblies";
    license = licenses.mit;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "moltemplate.sh";
  };
}
