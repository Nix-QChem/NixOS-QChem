{ stdenv, lib, gfortran, fetchFromGitHub, makeWrapper, bash, turbomole }:

stdenv.mkDerivation rec {
  pname = "cefine";
  version = "2.24";

  nativeBuildInputs = [
    gfortran
    makeWrapper
  ];

  propagatedBuildInputs = [ turbomole ];

  src = fetchFromGitHub  {
    owner = "grimme-lab";
    repo = pname;
    rev = "v${version}";
    sha256= "sha256-0vg8AXgdo1Qu81nhStoFWHoMCEuddDA8J/8eLd0JIx4=";
  };

  hardeningDisable = [ "format" ];

  dontConfigure = true;

  buildPhase = ''
    gfortran -o cefine cefine.f90
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp cefine $out/bin/.
  '';

  postFixup = let
    binSearchPath = lib.strings.makeSearchPath "bin" [ bash turbomole ];
  in ''
    wrapProgram $out/bin/cefine \
      --prefix PATH : "${binSearchPath}"
  '';

  meta = with lib; {
    description = "Non-interactive command-line wrapper around turbomoles define";
    license = licenses.lgpl3Only;
    homepage = "https://github.com/grimme-lab/cefine";
    platforms = platforms.linux;
  };
}
