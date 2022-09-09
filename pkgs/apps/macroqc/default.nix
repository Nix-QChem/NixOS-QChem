{ stdenv, lib, fetchurl, unzip, autoPatchelfHook, libllvm }:

stdenv.mkDerivation rec {
  pname = "MacroQC";
  version = "1.0.6-2022-09-09";

  src = fetchurl {
    url = "https://macroqc.hacettepe.edu.tr/src/binaries/macroqc.zip";
    hash = "sha256-5O4BMMowXM7UOShXLnS6L4rgQEZmU/osGyez/005bQk=";
  };

  unpackPhase = ''
    ${unzip}/bin/unzip ${src}
    cd macroqc
  '';

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [ libllvm ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp -r include lib share $out/.
    cp bin/macroqc $out/bin/.
  '';

  autoPatchelfIgnoreMissingDeps = true;

  meta = with lib; {
    description = "An electronic structure theory software for large-scale applications";
    homepage = "https://macroqc.hacettepe.edu.tr/index.html";
    license = licenses.unfree;
    platforms = platforms.linux;
    mainProgram = "macroqc";
    maintainers = [ maintainers.sheepforce ];
  };
}
