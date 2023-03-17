{ stdenv, lib, fetchFromGitHub, boost
, cmake, blas, lapack, libxml2, hdf5-mpi, fftw, mpi, python3
}:

stdenv.mkDerivation rec {
  pname = "qmcpack";
  version = "3.16.0";

  src = fetchFromGitHub {
    owner = "QMCPACK";
    repo = "qmcpack";
    rev = "v${version}";
    sha256 = "sha256-/1bWnE6mbKYSuApwHK92ia5aXKfq7n4KTca5rn0rixI=";
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
