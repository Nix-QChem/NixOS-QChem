{ stdenv, lib, fetchFromGitHub, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "vossvolvox";
  version = "21.11.2021";

  src = fetchFromGitHub {
    owner = "vosslab";
    repo = pname;
    rev = "5d7bdc0b5d94be7d160ee9a5030b55214b87331a";
    hash = "sha256-gCaxSkCvpE5m4GLcezKJ/+clDuDwIAGMa1pJwaVqqL0=";
  };

  # Removes the CPU specific tunings.
  # The Makefile just puts every binary as "bin" and thus overrides
  # them one after another. Needs to be patched to actually keep
  # executables.
  postPatch = ''
    substituteInPlace src/Makefile \
      --replace "-march=native -mtune=native" "" \
      --replace "../bin" "../bin/"
  '';

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  preBuild = ''
    mkdir bin
    cd src
  '';
  postBuild = "cd ..";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/${pname}}
    cp bin/* $out/bin/.
    cp xyzr/pdb_to_xyzr $out/bin
    cp xyzr/atmtypenumbers $out/share/${pname}/.

    runHook postInstall
  '';

  # Ensure that the atmtypenumbers is always in the directory of the pdb_to_xyzr execution
  postFixup = ''
    wrapProgram $out/bin/pdb_to_xyzr \
      --run "install -C -m 644 $out/share/${pname}/atmtypenumbers ."
  '';

  meta = with lib; {
    description = "Volume voxelator and calculator for PDBs";
    homepage = "https://github.com/vosslab/vossvolvox";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
