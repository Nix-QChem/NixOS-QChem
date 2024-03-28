{ stdenv
, lib
, gfortran
, fetchFromGitHub
, meson
, ninja
, pkg-config
, numsa
, mctc-lib
, test-drive
, lapack
, blas
, toml-f
, python3
}:

stdenv.mkDerivation rec {
  pname = "CPCM-X";
  version = "unstable-2024-03-04";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "7de0d7be85a10a19d60220a8d25eaa750f282019";
    hash = "sha256-wfK+dyyggpCCCOcADxny1Ee/zfK3JN+g6jFZdksMlT8=";
  };

  # Adds non-declared mctc-lib dependency and avoids subproject download
  patches = [ ./build.patch ];

  postPatch = ''
    substituteInPlace config/install-mod.py \
      --replace "#!/usr/bin/env python" "#!/usr/bin/env python3"
  '';

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    gfortran
    meson
    ninja
    pkg-config
    python3
  ];

  buildInputs = [
    mctc-lib
    (lib.getDev mctc-lib)
    test-drive
    lapack
    blas
    toml-f
    numsa
  ];

  meta = with lib; {
    description = "Extended conductor-like polarizable continuum solvation model";
    homepage = "https://github.com/grimme-lab/CPCM-X";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
