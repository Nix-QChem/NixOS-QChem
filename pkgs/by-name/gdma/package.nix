{ stdenv, lib, gfortran, fetchFromGitLab, python3, git }:

let rev = "6b8e81ec141fade2cc24c142d58ce82178c85f61";

in stdenv.mkDerivation rec {
  pname = "gdma";
  version = "2.3.3-unstable-2023-06-03";

  nativeBuildInputs = [
    gfortran
    git
  ];

  buildInputs = [ python3 ];

  # Needs the .git subdirectory to generate a version string.
  src = fetchFromGitLab {
    owner = "anthonyjs";
    repo = "gdma";
    inherit rev;
    hash = "sha256-aepRI8K/Zy02R0RJtgWUZDBo7l+iWhqMj0fmrJaSuCk=";
  };

  patches = [
    # Allow longer file paths
    ./filepath.patch

    # Remove git logic to obtain version string and hardcode it instead
    ./gitversion.patch
  ];

  postPatch = ''
    patchShebangs src/version.py
    substituteInPlace src/version.py \
      --subst-var-by "COMMIT" "${rev}"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -p bin/gdma $out/bin

    runHook postInstall
  '';

  hardeningDisable = [ "format" ];

  meta = with lib; {
    description = "Global Distributed Multipole Analysis from Gaussian Wavefunctions";
    homepage = "http://www-stone.ch.cam.ac.uk/pub/gdma/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
