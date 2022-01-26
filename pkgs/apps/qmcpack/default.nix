{ stdenv, lib, fetchFromGitHub, boost
, cmake, blas, lapack, libxml2, hdf5-mpi, fftw, mpi, python3
}:

stdenv.mkDerivation rec {
  pname = "qmcpack";
  version = "3.12.0";

  src = fetchFromGitHub {
    owner = "QMCPACK";
    repo = "qmcpack";
    rev = "v${version}";
    sha256 = "1x6q6a2krik50gsxv4xhpwbrgkac14nv7i4ax30g14hc7xjx3dka";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    boost
    blas
    lapack
    libxml2
    hdf5-mpi
    fftw
    python3
  ];

  propagatedBuildInputs = [ mpi ];

  meta = with lib; {
    description = "Many-body ab initio Quantum Monte Carlo code for electronic structure calculations";
    homepage = "https://www.qmcpack.org";
    license = licenses.ncsa;
    maintainers = [ maintainers.markuskowa ];
  };
}
