{ lib, buildPythonPackage, fetchFromGitHub, numpy, scipy, pbr, networkx }:

buildPythonPackage rec {
  pname = "vermouth";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "marrink-lab";
    repo = "vermouth-martinize";
    rev = "v${version}";
    hash = "sha256-Ix17LRY8f9z9UBDELbpaIO7Tt2SvxKtIXr0kgCV24cE=";
  };

  postPatch = ''
    substituteInPlace ./setup.cfg --replace 'networkx ~= 2.0' 'networkx'
  '';

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
    maintainers = [ maintainers.sheepforce ];
    license = [ licenses.asl20 ];
  };
}

