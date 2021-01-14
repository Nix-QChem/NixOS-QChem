{ stdenv, buildPythonPackage, cython, numpy
, qchem, hdf5
} :

buildPythonPackage {
  pname = "PyCheMPS2";
  inherit (qchem.chemps2) version src meta;

  nativeBuildInputs = [ cython ];

  buildInputs = [ qchem.chemps2 hdf5 ];

  propagatedBuildInputs = [ numpy ];

  preConfigure = ''
    cd PyCheMPS2
  '';
}
