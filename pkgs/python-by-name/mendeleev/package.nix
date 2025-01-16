{ buildPythonPackage
, fetchFromGitHub
, lib
, pythonRelaxDepsHook
, numpy
, colorama
, pydantic
, pyfiglet
, pygments
, pandas
, sqlalchemy
, bokeh
, plotly
, seaborn
, poetry-core
, deprecated
}:

buildPythonPackage rec {
  pname = "mendeleev";
  version = "0.20.1";

  src = fetchFromGitHub {
    owner = "lmmentel";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-NA0pgfhgk1XBA1Ei8IUtYuw8rh53Dp4XBqZ+5btzhYU=";
  };

  pyproject = true;

  build-system = [
    poetry-core
  ];

  dependencies = [
    pydantic
    numpy
    colorama
    pyfiglet
    pygments
    pandas
    sqlalchemy
    bokeh
    plotly
    seaborn
    deprecated
  ];

  nativeBuildInputs = [
    pythonRelaxDepsHook
  ];
  pythonRelaxDeps = [
    "pyfiglet"
  ];

  pythonImportsCheck = [ "mendeleev" ];

  meta = with lib; {
    description = "Python package for accessing various properties of elements, ions and isotopes in the periodic table of elements";
    homepage = "https://github.com/lmmentel/mendeleev";
    license = licenses.mit;
    maintainers = [ maintainers.sheepforce ];
  };
}
