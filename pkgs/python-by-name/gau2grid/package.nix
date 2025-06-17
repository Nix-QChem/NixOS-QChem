{ lib, buildPythonPackage, fetchFromGitHub, cmake
, pythonAtLeast
, numpy
, setuptools
, version ? "2.0.8"
, hash ? "sha256-5FRN2IUN79oylLGFoRQobK1altZiSuPt9gXCzeP+iC4="
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
    inherit hash;
    owner = "psi4";
    repo = pname;
    rev = "v" + version;
  };

  meta = with lib; {
    description = "Fast computation of a gaussian and its derivative on a grid";
    homepage = "https://github.com/dgasmith/gau2grid";
    license = licenses.bsd3;
    platforms = platforms.all;
  };
}
