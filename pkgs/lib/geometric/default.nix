{ buildPythonPackage, lib, fetchPypi
, networkx, numpy, scipy, six
, pytest-cov, pytest
}:

buildPythonPackage rec {
  pname = "geometric";
  version = "0.9.7.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1p9vxvzvnb6nnqlxl2r75jrih9bbqqbsm5zjn3i311qq3b1whsbg";
  };

  propagatedBuildInputs = [
    networkx
    numpy
    scipy
    six
    pytest-cov
  ];

  checkInputs = [
    pytest
    pytest-cov
  ];

  meta = with lib; {
    description = "Geometry optimization code for molecular structures";
    homepage = "https://github.com/leeping/geomeTRIC";
    license = [ licenses.bsd3 ];
    maintainers = [ maintainers.markuskowa ];
  };
}
