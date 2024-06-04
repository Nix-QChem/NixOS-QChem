{ buildPythonPackage
, fetchFromGitHub
, lib
, matplotlib
, lxml
, numpydoc
, nose
}:

buildPythonPackage rec {
  pname = "svgutils";
  version = "0.3.4";

  src = fetchFromGitHub {
    owner = "btel";
    repo = "svg_utils";
    rev = "v${version}";
    hash = "sha256-ITvZx+3HMbTyaRmCb7tR0LKqCxGjqDdV9/2taziUD0c=";
  };

  propagatedBuildInputs = [
    matplotlib
    lxml
    numpydoc
    nose
  ];

  meta = with lib; {
    description = "Python tools to create and manipulate SVG files ";
    homepage = "https://github.com/btel/svg_utils";
    license = licenses.mit;
    maintainers = [ maintainers.sheepforce ];
  };
}
