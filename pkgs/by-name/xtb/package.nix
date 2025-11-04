{ stdenv
, lib
, gfortran
, fetchFromGitHub
, fetchpatch
, meson
, ninja
, pkg-config
, makeWrapper
, blas
, lapack
, writeTextFile
, mctc-lib
, test-drive
, tblite
, toml-f
, simple-dftd3
, dftd4
, multicharge
, cpcm-x
, git
, enableTurbomole ? false
, turbomole
, enableOrca ? false
, orca
, cefine
}:

assert !blas.isILP64 && !lapack.isILP64;

let
  description = "Semiempirical extended tight-binding program package";

  binSearchPath = lib.strings.makeSearchPath "bin" (
    lib.optional enableTurbomole turbomole
    ++ lib.optional enableOrca orca
    ++ lib.optional enableTurbomole cefine
  );

in
stdenv.mkDerivation rec {
  pname = "xtb";
  version = "6.7.1";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-+qgXSMwzD0xSycZIRTokt77fZHHZQ++Npzr7NLlypOA=";
  };

  patches = [
    ./build.patch
    ./pkg-config.patch

    # Fixes QCG crash with current xTB versions
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/grimme-lab/xtb/pull/1089.patch";
      hash = "sha256-ZB/yz1EAfuxVwYFr5xjpgrDg09/3YLC45AzXkuzax84=";
    })
  ];

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    gfortran
    meson
    ninja
    pkg-config
    makeWrapper
    git
  ];

  buildInputs = [
    blas
    lapack
    mctc-lib
    tblite
    test-drive
    toml-f
    simple-dftd3
    dftd4
    multicharge
    cpcm-x
  ];

  hardeningDisable = [ "format" ];

  postFixup = ''
    wrapProgram $out/bin/xtb \
      --prefix PATH : "${binSearchPath}" \
      --set-default XTBPATH $out/share/xtb
  '';

  doCheck = true;
  preCheck = ''
    export OMP_NUM_THREADS=2
  '';

  passthru = { inherit enableOrca enableTurbomole; };

  meta = with lib; {
    inherit description;
    homepage = "https://github.com/grimme-lab/xtb";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
