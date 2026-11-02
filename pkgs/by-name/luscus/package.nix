{ stdenv
, lib
, fetchurl
, cmake
, pkg-config
, libGLU
, libGL
, gtk3
, libx11
, wrapGAppsHook3
}:

stdenv.mkDerivation rec {
  pname = "luscus";
  version = "0.8.6";

  src = fetchurl {
    url = "mirror://sourceforge/project/luscus/luscus_${version}.tar.gz";
    hash = "sha256-I+njP7tjscIAJQis0lRNP4k37fPmxAJ/+nDalb4yKtA=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt --replace '"$ENV{HOME}/.luscus"' "$out/etc"
    substituteInPlace gv_system.c --replace "/etc/luscus" "$out/etc"
    for i in $(find -name "*.sh"); do
      substituteInPlace $i --replace '$HOME/.luscus/' "$out/bin/"
    done

    #sed -i "s|\$RUNDIR/|$out/bin/|" ./*/*/*.sh
  '';

  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  # This is missing for some reason:
  env.LDFLAGS = "-lGLU -lGL";
  env.NIX_CFLAGS_COMPILE = "-fcommon";

  nativeBuildInputs = [ cmake pkg-config wrapGAppsHook3 ];
  buildInputs = [ libGLU libGL gtk3 libx11 ];

  postInstall = ''
    find ../ -name "babel_*.sh" -exec install -m 755 \{} $out/bin \; -print
  '';

  meta = with lib; {
    description = "Portable GUI for MOLCAS and other quantum chemical software";
    homepage = "http://luscus.sourceforge.net";
    license = licenses.afl3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}

