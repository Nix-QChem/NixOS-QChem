{ stdenv
, lib
, requireFile
, makeWrapper
, writeScriptBin
, bash
, perl
, tcl
, tk
, netcdf
, libGLU
, libX11
, libxinerama
, libxi
, fltk
, vrpn
, flex
, bison
, mesa
, cudatoolkit
  # New
, atkmm
, libxkbcommon
, pango
, dbus
, gtk3
, gdk-pixbuf
  #
, autoPatchelfHook
}:
assert
lib.asserts.assertMsg
  (stdenv.isLinux && stdenv.isx86_64)
  "The VMD binaries require an x86_64 linux OS with CUDA support.";

let homepage = "https://www.ks.uiuc.edu/Research/vmd/";

in stdenv.mkDerivation rec {
  pname = "vmd";
  version = "2.0.0";

  src = requireFile {
    url = homepage;
    name = "vmd-2.0.0.bin.LINUXAMD64.tar.gz";
    sha256 = "sha256-dBnGp7VV7KRD/KaUu+bpLv79sHDYMJUZbtrerQhx1+Y=";
  };

  nativeBuildInputs = [
    perl
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    libGLU
    libX11
    libxinerama
    libxi
    tcl
    tk
    netcdf
    fltk
    vrpn
    flex
    bison
    atkmm
    libxkbcommon
    pango
    dbus
    gtk3
    gdk-pixbuf
    mesa
    cudatoolkit.out
    cudatoolkit.lib
  ];

  postPatch = ''
    substituteInPlace ./configure \
      --replace '/usr/local' "$out" \
      --replace '-ll' '-lfl'

    patchShebangs ./configure
  '';

  sourceRoot = "vmd-${version}";

  # non-standard configure script
  configurePhase = ''
    ./configure
  '';

  dontBuild = true;

  preInstall = ''
    cd src
  '';

  postInstall = ''
    # Needs libcuda.so.1 but only finds libcuda.so
    ln -s ${cudatoolkit}/lib/stubs/libcuda.so $out/lib/libcuda.so.1
    ln -s ${cudatoolkit}/lib/libcudart.so $out/lib/libcudart.so.9.0

    # Makes tachyon available
    ln -s $out/lib/vmd/{stride,surf,tachyon}_LINUXAMD64 $out/bin/.
  '';

  # libnvcuvid.so depends on the linuxPackages.nvidia_x11.
  # This might be overridden in configuration.nix and should be detected at runtime at
  # /var/run/opengl-driver/lib
  autoPatchelfIgnoreMissingDeps = true;

  postFixup = ''
    wrapProgram $out/bin/vmd \
      --set "LC_ALL" "C"
  '';

  enableParallelBuilding = true;

  dontCheckForBrokenSymlinks = true;

  meta = with lib; {
    inherit homepage;
    description = "Molecular dynamics visualisation program";
    license = licenses.unfree;
    maintainers = [ maintainers.sheepforce ];
    platforms = [ "x86_64-linux" ];
  };
}
