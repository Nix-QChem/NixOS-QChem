{ stdenv, fetchurl, bash, pkgconfig,
  unzip, which, coreutils,
  libuuid, attr, xfsprogs, cppunit,
  zlib, openssl, sqlite, jre, openjdk, ant
} :

stdenv.mkDerivation rec { 
  version = "6.17";
  name = "beegfs-${version}";

  src = fetchurl {
    url = "https://git.beegfs.com/pub/v6/repository/archive.tar.bz2?ref=${version}";
    sha256 = "10xs7gzdmlg23k6zn1b7jij3lljn7rr1j6h476hq4lbg981qk3n3";
  };

  nativeBuildInputs = [ which bash unzip pkgconfig cppunit openjdk ant];
  buildInputs = [ libuuid attr xfsprogs zlib openssl sqlite jre ];
  postPatch = ''
    find -type f -executable -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
    find -type f -name Makefile -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
    find -type f -name Makefile -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
    find -type f -name "*.mk" -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
  '';

  subdirs = [
    "beegfs_thirdparty/build"
    "beegfs_opentk_lib/build"
    "beegfs_common/build"
    "beegfs_admon/build"
    "beegfs_java_lib/build"
    "beegfs_ctl/build"
    "beegfs_fsck/build"
    "beegfs_helperd/build"
    "beegfs_meta/build"
    "beegfs_mgmtd/build"
    "beegfs_online_cfg/build"
    "beegfs_storage/build"
    "beegfs_utils/build"
  ];

#make ${enableParallelBuilding:+-j${NIX_BUILD_CORES} -l${NIX_BUILD_CORES}} \
  buildPhase = ''
    for i in ${toString subdirs}; do 
      make -j4 -C $i
    done
    make -j4 -C beegfs_admon/build admon_gui
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/share/doc $out/include

    cp beegfs_admon/build/beegfs-admon $out/bin 
    # patch paths, copy jar
    cp beegfs_admon/build/dist/usr/bin/beegfs-admon-gui $out/bin 
    cp beegfs_admon_gui/dist/beegfs-admon-gui.jar $out/lib
    cp beegfs_admon/build/dist/etc/beegfs-admon.conf $out/share/doc

    cp beegfs_java_lib/build/jbeegfs.jar $out/lib
    cp beegfs_java_lib/build/libjbeegfs.so $out/lib

    cp beegfs_ctl/build/beegfs-ctl $out/bin
    cp beegfs_fsck/build/beegfs-fsck $out/bin

    cp beegfs_utils/scripts/beegfs-check-servers $out/bin
    cp beegfs_utils/scripts/beegfs-df $out/bin
    cp beegfs_utils/scripts/beegfs-net $out/bin     

    cp beegfs_helperd/build/beegfs-helperd $out/bin
    cp beegfs_helperd/build/dist/etc/beegfs-helperd.conf $out/share/doc

    cp beegfs_client_module/build/dist/sbin/beegfs-setup-client $out/bin
    cp beegfs_client_module/build/dist/etc/beegfs-client.conf $out/share/doc 

    cp beegfs_meta/build/beegfs-meta $out/bin
    cp beegfs_meta/build/dist/sbin/beegfs-setup-meta $out/bin
    cp beegfs_meta/build/dist/etc/beegfs-meta.conf $out/share/doc

    cp beegfs_mgmtd/build/beegfs-mgmtd $out/bin
    cp beegfs_mgmtd/build/dist/sbin/beegfs-setup-mgmtd $out/bin
    cp beegfs_mgmtd/build/dist/etc/beegfs-mgmtd.conf $out/share/doc

    cp beegfs_storage/build/beegfs-storage $out/bin
    cp beegfs_storage/build/dist/sbin/beegfs-setup-storage $out/bin
    cp beegfs_storage/build/dist/etc/beegfs-storage.conf $out/share/doc

    cp beegfs_opentk_lib/build/libbeegfs-opentk.so $out/lib

    cp -r beegfs_client_devel/include/* $out/include
  '';

  postFixup = ''
    substituteInPlace $out/bin/beegfs-admon-gui \
      --replace " java " " ${jre}/bin/java " \
      --replace "/opt/beegfs/beegfs-admon-gui/beegfs-admon-gui.jar" \
                "$out/lib/beegfs-admon-gui.jar"
  '';

  doCheck = true;

  checkPhase = ''
    beegfs_common/build/test-runner --text
  '';

  meta = with stdenv.lib; {
    description = "High performance distributed filesystem";
    homepage = "https://www.beegfs.io";
    licenses = {
      fullName = "BeeGFS_EULA";
      url = "https://www.beegfs.io/docs/BeeGFS_EULA.txt";
      free = true;
    };
    maintainters = with maintainers; [ markuskowa ];
  };
}


