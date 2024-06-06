{ stdenv, lib, fetchurl, autoPatchelfHook, makeWrapper, xtb }:

stdenv.mkDerivation rec {
  pname = "xtb-iff";
  version = "1.1";

  src = fetchurl {
    url = "https://github.com/grimme-lab/xtbiff/releases/download/v${version}/xtbiff.tar.xz";
    hash = "sha256-bV3uELo57LHiY3S3v4LiNk2OvtW281zc5M7XMkXClvU=";
  };

  unpackPhase = ''
    runHook preUnpack

    tar -xvf ${src}

    runHook postUnpack
  '';

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install xtbiff $out/bin

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/xtbiff \
      --set-default XTBPATH ${xtb}/share/xtb
  '';

  meta = with lib; {
    description = "General Intermolecular Force Field based on Tight-Binding Quantum Chemical Calculations";
    homepage = "https://github.com/grimme-lab/xtbiff";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
