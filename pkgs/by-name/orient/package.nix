{ stdenv, lib, fetchFromGitLab, writeTextFile, gfortran, blas, lapack,
  xorg, python3, libGL, libGLU, freeglut
}:

let
  pythonWP = python3.withPackages (p: with p; [
    numpy
  ]);

  # Not inlined with a cat EOF, as the string interpolation with ''${} is
  # handled differently.
  makeInclude = writeTextFile {
    name = "Flags";
    text = ''
      FC        := gfortran
      FFLAGS    := ''$(DEBUG) -DF2003

      LIBRARIES := -L${blas}/lib
      LIBS      := -llapack -lblas

      X11LIBDIR := -L${xorg.libX11}/lib
      X11LIB    := -lX11 -lm

      ifeq "''${OPENGL}" "yes"
        OGLLIBDIR := -L${libGL}/lib -L${libGLU}/lib -L${freeglut}/lib
        OGLLIB    := -lglut -lGL -lGLU
        FFLAGS    := ''${FFLAGS} -DOPENGL
      endif

      LDFLAGS   := ''$(DEBUG)
      LIBRARIES := ''${OGLLIBDIR} ''${X11LIBDIR} ''${LIBRARIES}
      LIBS      := ''${LIBS} -lpthread -lgfortran -lc ''${OGLLIB} ''${X11LIB}

      MOD       := mod
    '';
  };

in stdenv.mkDerivation (finalAttrs: {
  pname = "orient";
  version = "5.0.10";

  src = fetchFromGitLab {
    owner = "anthonyjs";
    repo = "orient";
    rev = "64cab885b460239d195c2cf239ad892fea005f22";
    hash = "sha256-LPqYbMzzpK0CCxShJOzCyf6xykBETA/oys6C760cJjg=";
  };

  nativeBuildInputs = [
    gfortran
  ];

  buildInputs = [
    blas
    lapack
    libGL
    libGLU
    freeglut
    xorg.libX11
  ];

  propagatedBuildInputs = [ pythonWP ];

  patches = [
    ./MakePrefix.patch
    ./UseCommitEnvVar.patch
  ];

  postPatch = ''
    patchShebangs .

    export ORIENT_COMMIT=${finalAttrs.src.rev}

    # Write a custom Makefile for Gfortran/Nix
    rm ./x86-64/gfortran/Flags
    cp ${makeInclude} ./x86-64/gfortran/Flags
  '';

  makeFlags = [ "COMPILER=gfortran" "OPENGL=yes" ];

  meta = with lib; {
    description = "Program for carrying out calculations of various kinds for an assembly of interacting molecules";
    homepage = "https://gitlab.com/anthonyjs/orient";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
})
