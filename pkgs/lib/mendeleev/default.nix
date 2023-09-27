{ buildPythonPackage
, fetchFromGitHub
, lib
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
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "lmmentel";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-iVOc2O+Pavc5nlzuwe3HpP0H2Esif8vhQWtTLT/pBjA=";
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

  pythonImportsCheck = [ "mendeleev" ];

  meta = with lib; {
    description = "Python package for accessing various properties of elements, ions and isotopes in the periodic table of elements";
    homepage = "https://github.com/lmmentel/mendeleev";
    license = licenses.mit;
    maintainers = [ maintainers.sheepforce ];
  };
}
