{ stdenv, buildPythonPackage, setuptools, cython, numpy
, chemps2, hdf5
} :

buildPythonPackage {
  pname = "PyCheMPS2";
  inherit (chemps2) version src meta;

  pyproject = true;
  build-system = [ setuptools ];

  nativeBuildInputs = [ cython ];

  buildInputs = [ chemps2 hdf5 ];

  propagatedBuildInputs = [ numpy ];

  preConfigure = ''
    cd PyCheMPS2
  '';
}
