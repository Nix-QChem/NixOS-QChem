{ stdenv, fetchurl, bash, pkgconfig, unzip, which, coreutils,
  libuuid, attr, xfsprogs, cppunit,
  zlib, openssl, sqlite, openjdk,
} :

let
  version = "6.14";
in
  stdenv.mkDerivation { 
    name = "beegfs-${version}";

    src = fetchurl {
      url = "https://git.beegfs.com/pub/v6/repository/archive.tar.bz2?ref=${version}";
      sha256 = "0nr4rz24w5qrq019rm3m1p530qicah22lkl8glkrxcwg5lwp92hs";
    };

    nativeBuildInputs = [ which bash unzip pkgconfig cppunit ];
    buildInputs = [ libuuid attr xfsprogs zlib openssl sqlite openjdk ];
    postPatch = ''
      find -type f -executable -exec sed -i "s:/bin/bash:/usr/bin/env bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
      find -type f -name "*.mk" -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
    '';


    buildPhase = ''
      make -j4 -C beegfs_thirdparty/build
      make -j4 -C beegfs_opentk_lib/build
      make -j4 -C beegfs_common/build

      make -j4 -C beegfs_admon/build/
      make -j4 -C beegfs_ctl/build/
      make -j4 -C beegfs_fsck/build/
      make -j4 -C beegfs_helperd/build/
      make -j4 -C beegfs_meta/build/
      make -j4 -C beegfs_mgmtd/build/
      make -j4 -C beegfs_online_cfg/build/
      make -j4 -C beegfs_storage/build/
      make -j4 -C beegfs_utils/build/

    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/lib

      cp beegfs_admon/build/beegfs-admon $out/bin 
      cp beegfs_admon/build/dist/usr/bin/beegfs-admon-gui $out/bin 

      cp beegfs_ctl/build/beegfs-ctl $out/bin
      cp beegfs_fsck/build/beegfs-fsck $out/bin

      cp beegfs_utils/scripts/beegfs-check-servers $out/bin
      cp beegfs_utils/scripts/beegfs-df $out/bin

      cp beegfs_helperd/build/beegfs-helperd $out/bin
      cp beegfs_client_module/build/dist/sbin/beegfs-setup-client $out/bin

      cp beegfs_meta/build/beegfs-meta $out/bin
      cp beegfs_meta/build/dist/sbin/beegfs-setup-meta $out/bin

      cp beegfs_mgmtd/build/beegfs-mgmtd $out/bin
      cp beegfs_mgmtd/build/dist/sbin/beegfs-setup-mgmtd $out/bin

      cp beegfs_storage/build/beegfs-storage $out/bin
      cp beegfs_storage/build/dist/sbin/beegfs-setup-storage $out/bin

      cp fhgfs_opentk_lib/build/libbeegfs-opentk.so $out/lib
    '';

    doCheck = true;

    checkPhase = ''
      fhgfs_common/build/test-runner --text
    '';

    meta = {
      description = "High performance distributed filesystem";
      homepage = "https://www.beegfs.io";
    };
  }


