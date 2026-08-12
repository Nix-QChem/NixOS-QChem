{ stdenv
, lib
, meson
, ninja
, pkg-config
, hostname
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

let lwoniom = fetchFromGitHub {
      owner = "crest-lab";
      repo = "lwoniom";
      rev = "ab66c7ebc3066328a8fc313dc783aec9b773cad2";
      hash = "sha256-9FFlaGEHhsdS+23/7FnrteGwI9pvHb/q5A8C3iJxwnQ=";
    };
    libpvol = fetchFromGitHub {
      owner = "neudecker-group";
      repo = "libpvol";
      rev = "55f4a7362ac81a119b97484f7fa0de577209146f";
      hash = "sha256-9b6Z8bFZccU4TDpWj4lCLgd7BHGiZwRBkv23FaO5rdA=";
    };

in stdenv.mkDerivation rec {
  pname = "crest";
  version = "unstable-2026-06-16";

  src = fetchFromGitHub {
    owner = "crest-lab";
    repo = pname;
    rev = "cfdc301f759686b0fd66ced63b5ddbd6c693fa4f";
    hash = "sha256-QXYkdGnn1KXa7tlQFsT1rsbDbdtqQVcSY3i6Odtj15Y=";
  };

  patches = [
    # Fix static linking and missing MCTC-Lib dependency
    ./meson-build.patch
    # add missing function arguments to tblite
    ./tblite-api.patch
  ];

  # Meson subprojects that are not packaged in nixpkgs are vendored from the
  # pinned upstream sources, matching the directory names declared in the
  # corresponding *.wrap files.
  postPatch = ''
    chmod -R +rwx ./subprojects
    cp -r ${gfn0.src}/* ./subprojects/gfn0/.
    cp -r ${gfnff.src}/* ./subprojects/gfnff/.
    cp -r ${lwoniom}/* ./subprojects/lwoniom/.
    cp -r ${libpvol}/* ./subprojects/pvol/.
    chmod -R +rwx ./subprojects
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gfortran
    hostname
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

  mesonFlags = [
    "-Dla_backend=netlib"
    "-Ddefault_library=shared"
    "-DWITH_LIBPVOL=true"
  ];

  # Dynamic libraries are not installed by default and need to be installed
  # manually.
  postInstall = ''
    mkdir -p $out/lib
    cp ./libcrest.so $out/lib/.
  '';

  doCheck = true;

  meta = with lib; {
    description = "Conformer-Rotamer Ensemble Sampling Tool based on the xtb Semiempirical Extended Tight-Binding Program Package";
    license = licenses.gpl3Only;
    homepage = "https://github.com/grimme-lab/crest";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
