{ buildPythonPackage
, lib
, fetchFromGitHub
, boost
, swig
, numpy
, sphinx
, autodock-vina
, openbabel-bindings
}:

buildPythonPackage rec {
  inherit (autodock-vina) pname version src meta;

  # Remove hardcoded include paths and fix version constraint formats
  patches = [
    ./python-boost.patch
  ];

  postPatch = ''
    substituteInPlace build/python/setup.py \
      --subst-var-by "boost" ${boost} \
      --replace "'src/lib" "'../../src/lib"

    export PATH=$PATH:${swig}/bin
  '';

  env.NIX_CFLAGS_COMPILE = "-Wno-error=parentheses";

  nativeBuildInputs = [ sphinx ];

  buildInputs = [ swig ];

  propagatedBuildInputs = [ autodock-vina numpy boost openbabel-bindings ];

  preBuild = "cd build/python";

  pythonImportsCheck = [ "vina" ];
}
