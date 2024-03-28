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

in stdenv.mkDerivation rec {
  pname = "crest";
  version = "unstable-2024-03-19";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "2719412edf8bb606cebdd4cd6bbb4cdbd249e1e5";
    hash = "sha256-GakDssC4IoVUmRqKwOa6v6LWl37JUcpStUJN5huEP6c=";
  };

  patches = [ ./build.patch ];

  postPatch = ''
    chmod -R +rwx ./subprojects
    cp -r ${gfn0.src}/* ./subprojects/gfn0/.
    cp -r ${gfnff.src}/* ./subprojects/gfnff/.
    cp -r ${lwoniom}/* ./subprojects/lwoniom/.
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
  ];

  doCheck = true;

  meta = with lib; {
    description = "Conformer-Rotamer Ensemble Sampling Tool based on the xtb Semiempirical Extended Tight-Binding Program Package";
    license = licenses.gpl3Only;
    homepage = "https://github.com/grimme-lab/crest";
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
