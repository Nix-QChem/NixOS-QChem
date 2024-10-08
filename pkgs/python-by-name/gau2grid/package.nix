{ lib, buildPythonPackage, fetchFromGitHub, cmake
, pythonAtLeast
, numpy
, setuptools
, version ? "2.0.7"
, sha256 ? "1c01flf0xlm68dsv0a4n6bxglyj3x5mj8shmxglfpywbf74i3vnb"
# Configuration options
, maxAm ? 7
} :

buildPythonPackage rec {
  pname = "gau2grid";
  inherit version;

  nativeBuildInputs = [
    cmake
  ];

  propagatedBuildInputs = [
    numpy
    setuptools
  ];

  format = "other";

  cmakeFlags = [
    "-DMAX_AM=${toString maxAm}"
  ];

  src = fetchFromGitHub  {
    inherit sha256;
    owner = "dgasmith";
    repo = pname;
    rev = "v" + version;
  };

  patches = [
    ./distutils.patch
  ];

  meta = with lib; {
    description = "Fast computation of a gaussian and its derivative on a grid";
    homepage = "https://github.com/dgasmith/gau2grid";
    license = licenses.bsd3;
    platforms = platforms.all;
  };
}
