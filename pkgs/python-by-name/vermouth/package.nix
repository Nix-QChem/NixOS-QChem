{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools
, numpy
, scipy
, pbr
, networkx
}:

buildPythonPackage rec {
  pname = "vermouth";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "marrink-lab";
    repo = "vermouth-martinize";
    rev = "v${version}";
    hash = "sha256-3dC9duHicsQJG/leRAyYKLAFnUvMgHKAjM9J6OuU7U0=";
  };

  postPatch = ''
    substituteInPlace ./setup.cfg --replace 'networkx ~= 2.0' 'networkx'
  '';

  build-system = [
    pbr
    setuptools
  ];
  dependencies = [
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

