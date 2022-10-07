{ stdenv, lib, gfortran, fetchFromGitHub, cmake, makeWrapper, blas, lapack, writeTextFile
, mctc-lib, test-drive
, turbomole, enableTurbomole ? false
, orca, enableOrca ? false
, cefine
} :

let
  description = "Semiempirical extended tight-binding program package";

  binSearchPath = lib.strings.makeSearchPath "bin" ([ ]
    ++ lib.optional enableTurbomole turbomole
    ++ lib.optional enableOrca orca
    ++ lib.optional enableTurbomole cefine
  );

in stdenv.mkDerivation rec {
  pname = "xtb";
  version = "6.5.1";

  src = fetchFromGitHub  {
    owner = "grimme-lab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-9DTaHsK1NgcNbPKsjrVNvoWTyLdaqilZ59sAjAudS2M=";
  };

  nativeBuildInputs = [
    gfortran
    cmake
    makeWrapper
    test-drive
  ];

  buildInputs = [ blas lapack mctc-lib ];

  hardeningDisable = [ "format" ];

  postInstall = ''
    mkdir -p $out/lib/pkgconfig

    cat > $out/lib/pkgconfig/xtb.pc << EOF
    prefix=$out
    libdir=''${prefix}/lib
    includedir=''${prefix}/include

    Name: ${pname}
    Description: ${description}
    Version: ${version}
    Cflags: -I''${prefix}/include
    Libs: -L''${prefix}/lib -lxtb
    EOF
  '';

  postFixup = ''
    wrapProgram $out/bin/xtb \
      --prefix PATH : "${binSearchPath}"
  '';

  setupHooks = [ ./xtbHook.sh ];

  passthru = { inherit enableOrca enableTurbomole; };

  meta = with lib; {
    inherit description;
    homepage = "https://www.chemie.uni-bonn.de/pctc/mulliken-center/grimme/software/xtb";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
