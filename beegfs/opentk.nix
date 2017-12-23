{ stdenv, fetchurl, bash, pkgconfig, unzip, which, coreutils,
  cppunit, zlib, openssl, sqlite
} :

let
  version = "6.14";
in
  stdenv.mkDerivation { 
    name = "beegfs-opentk-${version}";

    src = fetchurl {
      url = "https://git.beegfs.com/pub/v6/repository/archive.tar.bz2?ref=${version}";
      sha256 = "0nr4rz24w5qrq019rm3m1p530qicah22lkl8glkrxcwg5lwp92hs";
    };

    propagatedNativeBuildInputs = [ which bash pkgconfig unzip cppunit ];
    propagatedBuildInputs = [ zlib openssl sqlite ];
    postPatch = ''
      find -type f -executable -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
      find -type f -name "*.mk" -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
    '';


    buildPhase = ''
      make -j4 -C beegfs_opentk_lib/build
    '';

    installPhase = ''
      mkdir -p $out/lib

      cp beegfs_opentk_lib/build/libbeegfs-opentk.so $out/lib
    '';

    meta = {
      description = "High performance distributed filesystem";
      homepage = "https://www.beegfs.io";
    };
  }

