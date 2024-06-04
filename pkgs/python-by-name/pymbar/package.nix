{ buildPythonPackage
, fetchFromGitHub
, lib
, numpy
, scipy
, numexpr
}:

buildPythonPackage rec {
  pname = "pymbar";
  version = "4.0.2";

  src = fetchFromGitHub {
    owner = "choderalab";
    repo = pname;
    rev = version;
    hash = "sha256-XNkGhEH/X5HBS92xqQHQj14JOSNkHXbLuAZ85cYhcPM=";
  };

  propagatedBuildInputs = [
    numpy
    scipy
    numexpr
  ];

  # Uses deprecated pytest invocation
  doCheck = false;

  pythonImportsCheck = [ "pymbar" ];

  meta = with lib; {
    description = "Implementation of the multistate Bennett acceptance ratio";
    homepage = "https://github.com/choderalab/pymbar";
    license = licenses.mit;
    maintainers = [ maintainers.sheepforce ];
  };
}
