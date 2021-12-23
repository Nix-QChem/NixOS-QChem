{ stdenv, lib, fetchpatch, makeWrapper, cmake
, gfortran, blas, lapack, fetchFromGitHub, xtb
} :

stdenv.mkDerivation rec {
  pname = "crest";
  version = "2.11.2";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-IdGo8VdUdw2GtWUaQywiJwhR20XNSEsZbGsGCmzsRlg=";
  };

  patches = [
    # gfortran compilation issues due to non-standard use of .eq. instead of .eqv.
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/grimme-lab/crest/pull/92.diff";
      sha256 = "0sdd7lpnhrrfagidfg438gv011mrmvdlpnnispcvjcbs7zxzzk2a";
    })
  ];

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
