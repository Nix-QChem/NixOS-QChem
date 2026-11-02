{ lib, stdenv, fetchurl, gtk3, pkg-config, libx11, libGL, libGLU, pango, wrapGAppsHook3 }:

stdenv.mkDerivation rec {
  pname = "gabedit";
  version = "2.5.1";

  src =
    let urlVersion = with lib.versions; "${major version}${minor version}${patch version}";
    in fetchurl {
      url = "mirror://sourceforge/project/gabedit/gabedit/Gabedit${urlVersion}/GabeditSrc${urlVersion}.tar.gz";
      hash = "sha256-78sAFRrzg/Zi1TWno2orDtLxTEIIYaKIB/6qnpOL/54=";
    };

  # Port from GTK2/GtkGLExt to GTK3.
  # src/Common/Gtk3Compat.{c,h} emulate the removed GTK2 drawing API (GdkGC, GdkPixmap)
  # on top of cairo, src/Common/GtkGLCompat.{c,h} replace GtkGLExt with a GLX context.
  # OpenGL requires the X11 GDK backend (XWayland works).
  patches = [ ./gtk3.patch ];

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    pango
    libGL
    libGLU
    libx11
  ];

  # Adapted from platforms/CONFIG.linux64
  configurePhase = ''
    runHook preConfigure

    cat > CONFIG << EOF
    GTKLIB = `pkg-config --libs gtk+-3.0 pangoft2 glu gl x11`
    GTKCFLAGS = `pkg-config --cflags gtk+-3.0 pangoft2 glu gl x11` -include $PWD/src/Common/Gtk3Compat.h

    OGLLIB=-lGL -lGLU

    LIBPTHREAD = -lpthread
    RM = rm -f
    RMTMP = rm -f tmp/*
    MAKE = make
    MKDIR = mkdir -p
    WIN32LIB =
    X11LIB = -lX11
    OMPLIB = -lgomp
    OMPCFLAGS = -fopenmp
    DRAWGEOMGL = -DDRAWGEOMGL

    COMMONCFLAGS = -Wformat -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2 -O2 -DENABLE_DEPRECATED \$(OMPCFLAGS) \$(DRAWGEOMGL) -Wformat-security -Wno-unused-variable -Wno-deprecated-declarations -Wno-error=implicit-function-declaration -Wno-error=int-conversion -Wno-error=incompatible-pointer-types -std=gnu17
    LDFLAGS = -Wl,-z,relro
    EOF

    runHook postConfigure
  '';

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp gabedit $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Graphical User Interface for FireFly (PC-Gamess), Gamess-US, Gaussian, Molcas, Molpro, MPQC, NWChem, OpenMopac, Orca, PSI4 and Q-Chem computational chemistry packages";
    homepage = "https://gabedit.sourceforge.net/";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "gabedit";
  };
}
