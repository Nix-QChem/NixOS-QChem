{ stdenv, lib, fetchurl, unzip, jdk, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "janpa";
  version = "2.02";

  src = fetchurl {
    url = "mirror://sourceforge/project/janpa/V${version}/binaries.zip";
    hash = "sha256-h0NgOMkamx2Tq0oLDVmAaHEPNOeCWI35yblSMiJ8ZZ0=";
  };

  unpackPhase = ''
    ${unzip}/bin/unzip ${src}
  '';

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ jdk ];

  installPhase = ''
    mkdir -p $out/bin
    cp *.jar $out/bin
    for p in $out/bin/*.jar; do
      makeWrapper ${jdk}/bin/java $out/bin/$(basename $p .jar) \
        --add-flags "-jar $p"
    done
  '';

  meta = with lib; {
    description = "Natural atomic orbital population analysis";
    homepage = "http://janpa.sourceforge.net/";
    license = licenses.bsdOriginal;
    platforms = platforms.linux;
    mainProgram = "janpa";
    maintainers = [ maintainers.sheepforce ];
  };
}
