{ lib, fetchFromGitHub, pkg-config
, buildPythonPackage, blas, libtensor, pybind11
, numpy, scipy, opt-einsum, h5py, tqdm, pandas, pyyaml
, setuptools
, pytest-cov, pytest
}:

assert !blas.isILP64;

buildPythonPackage rec {
  pname = "adcc";
  version = "0.15.14";

  src = fetchFromGitHub {
    owner = "adc-connect";
    repo = "adcc";
    rev = "v${version}";
    sha256 = "sha256-yEk4DcZXK+T2cdwoWnc4xZO8tG5moVAlTvv5RsvOIpY=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ blas libtensor pybind11 ];
  propagatedBuildInputs = [
    numpy
    scipy
    opt-einsum
    h5py
    tqdm
    pandas
    pyyaml
    setuptools
  ];

  NIX_CFLAGS_COMPILE = "-Wno-error=array-bounds";

  checkInputs = [ pytest pytest-cov ];

  # the check phase attempts to download files
  doCheck = false;

  meta = with lib; {
    description = "Framework for excited states with the algebraic-diagrammatic construction";
    homepage = "https://adc-connect.org/";
    license = licenses.lgpl3Only;
    maintainers = [ maintainers.markuskowa ];
  };
}
