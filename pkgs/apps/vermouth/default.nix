{ lib, buildPythonPackage, fetchFromGitHub, numpy, scipy, pbr, networkx }:

buildPythonPackage rec {
  pname = "vermouth";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "marrink-lab";
    repo = "vermouth-martinize";
    rev = "v${version}";
    hash = "sha256-bUUp6fD6Fo20PQjXlyTcWN0AvpAumc4ZAHp4FmA4ljM=";
  };

  nativeBuildInputs = [ pbr ];
  propagatedBuildInputs = [
    numpy
    scipy
    networkx
  ];

  preConfigure = "export PBR_VERSION=${version}";
  format = "pyproject";

  pythonImportsCheck = [ "vermouth" ];

  meta = with lib; {
    description = "Describe and apply transformation on molecular structures and topologies";
    homepage = "https://github.com/marrink-lab/vermouth-martinize";
    maintainers =  [ maintainers.sheepforce ];
    license = [ licenses.asl20 ];
  };
}

