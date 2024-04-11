{ lib, stdenv, fetchFromGitHub, gfortran, fftw, protobuf
, blas, lapack
, automake, autoconf, libtool, zlib, bzip2, libxml2, flex, bison
} :

assert (!blas.isILP64 && !lapack.isILP64);

stdenv.mkDerivation rec {
  pname = "qdng";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "quantum-dynamics-ng";
    repo = "QDng";
    rev = "v${version}";
    sha256 = "sha256-T59Bb014KSUOOFTFjPOrWmbF6GqIqAIyrb3Xe5TwU88=";
  };

  postPatch = ''
    patchShebangs tests/checktests.sh
  '';

  configureFlags = [
    "--enable-openmp"
    "--with-blas=-lblas"
    "--with-lapack=-llapack"
    "--disable-gccopt"
  ];

  enableParallelBuilding = false;

  preConfigure = ''
    ./genbs
  '';

  doCheck = true;

  buildInputs = [ fftw protobuf blas lapack
                  bzip2 zlib libxml2 flex bison ];
  nativeBuildInputs = [ automake autoconf libtool gfortran ];

  meta = with lib; {
    description = "Quantum dynamics program package";
    platforms = platforms.linux;
    maintainers = [ maintainers.markuskowa ];
    license = licenses.gpl3Only;
    homepage = "https://github.com/quantum-dynamics-ng/QDng";
  };
}
