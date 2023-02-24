{ buildPythonPackage
, meson
, ninja
, pkg-config
, tblite
, cffi
}:

buildPythonPackage rec {
  pname = tblite.pname;
  version = tblite.version;

  src = tblite.src;

  nativeBuildInputs = [ meson ninja pkg-config ];

  buildInputs = [ tblite ];

  propagatedBuildInputs = [ cffi ];

  format = "other";

  configurePhase = ''
    runHook preConfigure

    meson setup build python --prefix=$out
    cd build

    runHook postConfigure
  '';

  inherit (tblite) meta;
}
