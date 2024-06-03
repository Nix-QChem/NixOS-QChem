{ lib, stdenv, fetchurl, gtk2, pkg-config, xorg, libGL, libGLU, gnome2, pango }:

stdenv.mkDerivation rec {
  pname = "gabedit";
  version = "2.5.1";

  src =
    let urlVersion = with lib.versions; "${major version}${minor version}${patch version}";
    in fetchurl {
      url = "mirror://sourceforge/project/gabedit/gabedit/Gabedit${urlVersion}/GabeditSrc${urlVersion}.tar.gz";
      hash = "sha256-78sAFRrzg/Zi1TWno2orDtLxTEIIYaKIB/6qnpOL/54=";
    };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    gtk2
    pango
    libGL
    libGLU
    xorg.libX11
    gnome2.gtkglext
  ];

  # Adapted from platforms/CONFIG.linux64
  configurePhase = ''
    cat > CONFIG << EOF
    GTKLIB = `pkg-config gtk+-2.0 --libs`  -Wl,--export-dynamic -lgtkglext-x11-1.0 -lgdkglext-x11-1.0 -lGLU -lGL -lgtk-x11-2.0 -lX11 -lgdk-x11-2.0 -latk-1.0 -lpangoft2-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lcairo -lpango-1.0 -lfreetype -lz -lfontconfig -lgobject-2.0 -lgmodule-2.0 -lglib-2.0
    GTKCFLAGS = `pkg-config gtk+-2.0 --cflags` -I${gnome2.gtkglext}/include/gtkglext-1.0 -I${gnome2.gtkglext}/lib/gtkglext-1.0/include

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

    COMMONCFLAGS = -Wformat -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2 -O2 -DENABLE_DEPRECATED $(OMPCFLAGS) $(DRAWGEOMGL) -Wformat-security -Wno-unused-variable
    LDFLAGS = -Wl,-z,relro
    EOF
  '';

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin

    cp gabedit $out/bin/
  '';

  meta = with lib; {
    description = "Graphical User Interface for FireFly (PC-Gamess), Gamess-US, Gaussian, Molcas, Molpro, MPQC, NWChem, OpenMopac, Orca, PSI4 and Q-Chem computational chemistry packages";
    homepage = "https://gabedit.sourceforge.net/";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
