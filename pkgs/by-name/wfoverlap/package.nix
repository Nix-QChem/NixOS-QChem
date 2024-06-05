{ stdenv, lib, fetchFromGitHub, gfortran, blas, lapack } :

assert
  lib.asserts.assertMsg
  (blas.isILP64 || blas.passthru.implementation == "mkl")
  "64 bit integer BLAS implementation required.";

assert
  lib.asserts.assertMsg
  lapack.isILP64
  "64 bit integer LAPACK implementation required.";

stdenv.mkDerivation rec {
  pname = "wfoverlap";
  version = "24.08.2020";

  src = fetchFromGitHub {
    owner = "felixplasser";
    repo = "wfoverlap";
    rev = "76b51533770aaf32732e942cd81e6aa12770900e";
    hash = "sha256-bA8XRYGyCDDJ0dzCw5BDSJf+wcRj9A9mTfm+ukrbrlg=";
  };

  nativeBuildInputs = [ gfortran ];

  buildInputs = [
    gfortran
    blas
    lapack
  ];

  patches = [ ./Makefile.patch ];

  dontConfigure = true;

  preBuild = "cd wfoverlap/source";

  hardeningDisable = [ "format" ];

  installPhase = ''
    mkdir -p $out/bin
    cp wfoverlap.x $out/bin/.
  '';

  meta = with lib; {
    description = "Efficient calculation of wavefunction overlaps";
    homepage = "https://sharc-md.org/?page_id=309";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
