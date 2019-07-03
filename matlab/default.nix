{ stdenv, writeShellScriptBin, buildFHSUserEnv, optpath } :


let
  version = "2018a";

in buildFHSUserEnv {
  name="matlab";

  targetPkgs = pkgs: (with pkgs;
    [ udev
      coreutils
      alsaLib
      dpkg
      gcc49
      zlib
      freetype
      glib
      zlib
      fontconfig
      openssl
      which
      ncurses
      jdk11
      pam
      dbus_glib
      dbus
      pango
      gtk2-x11
      atk
      gdk_pixbuf
      cairo
    ]) ++ (with pkgs.xorg;
    [ libX11
    libXcursor
    libXrandr
    libXext
    libSM
    libICE
    libX11
    libXrandr
    libXdamage
    libXrender
    libXfixes
    libXcomposite
    libXcursor
    libxcb
    libXi
    libXScrnSaver
    libXtst
    libXt
    libXxf86vm
    ]);
  runScript = "${optpath}/matlab-${version}/bin/matlab";
}

