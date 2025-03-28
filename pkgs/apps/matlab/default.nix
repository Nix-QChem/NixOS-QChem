{ stdenv, writeShellScriptBin, buildFHSEnv
, slurmLicenseWrapper
, optpath ? null
, slurmLic ? null
} :

assert (optpath != null);

let
  version = "2018a";
  runPath = if slurmLic == null
    then
      "${optpath}/matlab-${version}"
    else
      slurmLicenseWrapper {
        name = "MATLAB";
        exe = "matlab";
        license = slurmLic;
        runProg = "${optpath}/matlab-${version}/bin/matlab";
      };


in buildFHSEnv {
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
      dbus-glib
      dbus
      pango
      gtk2-x11
      atk
      gdk-pixbuf
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
    runScript = "${runPath}/bin/matlab";
}

