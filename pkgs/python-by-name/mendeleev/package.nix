{ buildPythonPackage
, fetchFromGitHub
, lib
, pythonRelaxDepsHook
, numpy
, colorama
, pyfiglet
, pygments
, pandas
, sqlalchemy
, bokeh
, plotly
, seaborn
, poetry-core
}:

buildPythonPackage rec {
  pname = "mendeleev";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "lmmentel";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-s5VAXiIHAgOtxIwglelEmB8KNpUcJkQ0FvGRS/b99FM=";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    numpy
    colorama
    pyfiglet
    pygments
    pandas
    sqlalchemy
    bokeh
    plotly
    seaborn
    poetry-core
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
