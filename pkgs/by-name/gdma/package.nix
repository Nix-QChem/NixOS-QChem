{ stdenv, lib, gfortran, fetchgit, python3, git }:

stdenv.mkDerivation rec {
  pname = "gdma";
  version = "2.3.3";

  nativeBuildInputs = [
    gfortran
    git
  ];

  buildInputs = [ python3 ];

  # Needs the .git subdirectory to generate a version string.
  src = fetchgit {
    url = "https://gitlab.com/anthonyjs/${pname}.git";
    rev = "6b8e81ec141fade2cc24c142d58ce82178c85f61";
    hash = "sha256-7841FVV9tTJgRVEn1yEf5Qs2MGr3JLzG6GgXidnrwTQ=";
    leaveDotGit = true;
  };

  patches = [ ./filepath.patch ];
  postPatch = "patchShebangs src/version.py";

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
