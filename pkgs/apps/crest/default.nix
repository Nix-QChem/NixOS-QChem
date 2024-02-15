{ stdenv
, lib
, cmake
, gfortran
, blas
, lapack
, fetchFromGitHub
, tblite
, mctc-lib
, toml-f
, simple-dftd3
, dftd4
, multicharge
, gfn0
, gfnff
}:

stdenv.mkDerivation rec {
  pname = "crest";
  version = "unstable-2024-02-14";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "72dcc2d92f933424babb4905a3712559eb74915d";
    hash = "sha256-Ck38VZBTvbwcVbOOlU1sjzcBmk+NciVsKtG2fPeYeZA=";
  };

  postPatch = ''
    chmod -R +rwx ./subprojects
    cp -r ${gfnff.src}/* subprojects/gfnff/.
    cp -r ${gfn0.src}/* subprojects/gfn0/.
    chmod -R +rwx ./subprojects
  '';

  nativeBuildInputs = [
    cmake
    gfortran
  ];

  buildInputs = [
    tblite
    mctc-lib
    toml-f
    simple-dftd3
    dftd4
    multicharge
    blas
    lapack
  ];

  meta = with lib; {
    description = "Conformer-Rotamer Ensemble Sampling Tool based on the xtb Semiempirical Extended Tight-Binding Program Package";
    license = licenses.gpl3Only;
    homepage = "https://github.com/grimme-lab/crest";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
