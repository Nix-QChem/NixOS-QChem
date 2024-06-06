{ stdenv, lib, fetchFromGitHub, boost
, cmake, blas, lapack, libxml2, hdf5-mpi, fftw, mpi, python3
}:

stdenv.mkDerivation rec {
  pname = "qmcpack";
  version = "3.17.1";

  src = fetchFromGitHub {
    owner = "QMCPACK";
    repo = "qmcpack";
    rev = "v${version}";
    sha256 = "sha256-D/wcKULhAsOkyGHN1AlVs3av0yeOvouPMHLcmNmOUo8=";
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
