{ stdenv
, lib
, fetchFromGitLab
, gfortran
}:

let
  newtonx = import ../newton-x/common.nix { inherit fetchFromGitLab; };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "skitten";
  inherit (newtonx) version src;

  sourceRoot = "source/Skitten";

  nativeBuildInputs = [ gfortran ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    make FC=gfortran FFLAGS="-fopenmp -O3 -fcheck=all -Wall"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/skitten $out/bin/skitten
    runHook postInstall
  '';

  meta = with lib; {
    description = "SSE-based surface hopping dynamics program (Newton-X package component)";
    homepage = "https://gitlab.com/light-and-molecules/skitten";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "skitten";
  };
})
