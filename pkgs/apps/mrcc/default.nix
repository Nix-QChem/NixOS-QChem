{ stdenv
, lib
, makeWrapper
, requireFile
, writeScript
, writeTextFile
, which
, coreutils
}:

stdenv.mkDerivation rec {
  pname = "mrcc";
  version = "2022.03.18";

  nativeBuildInputs = [
    makeWrapper
  ];

  src =
    let
      dashVersion = lib.strings.replaceStrings [ "." ] [ "-" ] version;
    in
    requireFile rec {
      name = "mrcc.${dashVersion}.binary.tar.gz";
      sha256 = "59570fff722b80e1ca8ef46a8052c0569a8990120ad87f9fe0a180200a9729cc";
      url = "https://www.mrcc.hu/index.php/download-mrcc/mrcc-binary/send/4-mrcc-binary/31-mrcc-${dashVersion}-binary-tar";
      message = ''
        The MRCC source code and binaries are not publicly available. Obtain your own license at
        https://www.mrcc.hu and download the binaries at ${url}. Add the archive ${name} to the nix
        store by:
          nix-store --add-fixed sha256 ${name}
        and then rebuild.
      '';
    };

  unpackPhase = ''
    tar -xf $src
  '';

  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall

    # Move executables to $out
    mkdir -p $out/bin
    exes=$(find -type f -executable -not -name "MINP*")
    for exe in $exes; do
      cp $exe $out/bin/.
    done

    # Move the tests and basis sets to share and make a symlink for MRCC
    mkdir -p $out/share
    cp -r BASIS $out/share/.
    cp -r MTEST $out/share/.
    ln -s $out/share/BASIS $out/bin/.
    ln -s $out/share/MTEST $out/bin/.

    # Copy the manual also to share
    cp manual.pdf $out/share/.

    runHook postInstall
  '';

  postFixup = ''
    exes=$(find $out/bin/ -type f -executable)
    for exe in $exes; do
    wrapProgram $exe \
      --prefix PATH : ${stdenv.cc.coreutils_bin}/bin \
      --prefix PATH : ${which}/bin
    done
  '';

  meta = with lib; {
    description = "MRCC is a suite of ab initio and density functional quantum chemistry programs for high-accuracy electronic structure calculations.";
    homepage = "https://www.mrcc.hu/";
    license = licenses.unfree;
    mainProgram = "dmrcc";
    platforms = [ "x86_64-linux" ];
  };
}
