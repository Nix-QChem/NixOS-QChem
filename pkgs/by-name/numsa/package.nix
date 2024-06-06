{ stdenv
, lib
, gfortran
, fetchFromGitHub
, meson
, ninja
, pkg-config
, mctc-lib
, mstore
, test-drive
, blas
, lapack
, python3
}:

stdenv.mkDerivation rec {
  pname = "numsa";
  version = "unstable-2024-03-04";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "e1494543d5ab5c5dd60e5622f7b80043d63561bd";
    hash = "sha256-kpiviWepjgpP38IqeAgxbvEn6bIkkelfFHjC6Eg7E9g=";
  };

  # Avoid subproject downloads and use nix dependencies
  patches = [ ./build.patch ];

  postPatch = ''
    substituteInPlace ./config/install-mod.py \
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
    mstore
    test-drive
    blas
    lapack
  ];

  meta = with lib; {
    description = "Solvent accessible surface area calculation";
    homepage = "https://github.com/grimme-lab/numsa";
    license = with licenses ; [ lgpl3Only gpl3Only ];
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
