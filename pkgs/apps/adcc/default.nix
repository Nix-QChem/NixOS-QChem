{ lib, stdenv, fetchFromGitHub, pkg-config
, buildPythonPackage, blas, libtensor, pybind11
, numpy, scipy, opt-einsum, h5py, tqdm, pandas, pyyaml
, setuptools
, pytest-cov, pytest
}:

assert !blas.isILP64;

buildPythonPackage rec {
  pname = "adcc";
  version = "0.15.13";

  src = fetchFromGitHub {
    owner = "adc-connect";
    repo = "adcc";
    rev = "v${version}";
    sha256 = "1d119nyhbpd6y0jlk4v9vgjq0qvqr84p7blmhllsjrm0kdj7l9nv";
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
