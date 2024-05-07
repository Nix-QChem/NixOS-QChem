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
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "crest-lab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-YwPM43jVmiwQOCMXN8tyoxLHtPm36C7N+fEvYsVTp3A=";
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
