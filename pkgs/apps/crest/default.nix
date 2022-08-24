{ stdenv, lib, fetchpatch, makeWrapper, cmake
, gfortran, blas, lapack, fetchFromGitHub, xtb
} :

stdenv.mkDerivation rec {
  pname = "crest";
  version = "2.12";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-pTOcwKvAX9N2TQhfV9jJhik+0vLQB3MhHzR2fU4+oV0=";
  };

  nativeBuildInputs = [
    cmake
    makeWrapper
    gfortran
  ];

  buildInputs = [ blas lapack ];

  FFLAGS = "-ffree-line-length-512";

  hardeningDisable = [ "all" ];

  postFixup = ''
    wrapProgram $out/bin/crest \
      --prefix PATH : "${xtb}/bin"
  '';

  meta = with lib; {
    description = "Conformer-Rotamer Ensemble Sampling Tool based on the xtb Semiempirical Extended Tight-Binding Program Package";
    license = licenses.gpl3Only;
    homepage = "https://github.com/grimme-lab/crest";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
