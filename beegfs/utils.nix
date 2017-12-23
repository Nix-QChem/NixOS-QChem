{ stdenv, fetchurl, bash, coreutils, 
  beegfs-opentk, openjdk
} :

let
  version = "6.14";
in
  stdenv.mkDerivation { 
    name = "beegfs-utils-${version}";

    src = fetchurl {
      url = "https://git.beegfs.com/pub/v6/repository/archive.tar.bz2?ref=${version}";
      sha256 = "0nr4rz24w5qrq019rm3m1p530qicah22lkl8glkrxcwg5lwp92hs";
    };

    buildInputs = [ beegfs-opentk openjdk ];
    postPatch = ''
      find -type f -executable -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
      find -type f -name "*.mk" -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
    '';


    buildPhase = ''
      make -j4 -C beegfs_common/build/
      make -j4 -C beegfs_ctl/build/
      make -j4 -C beegfs_fsck/build/
      make -j4 -C beegfs_utils/build/
    '';

    installPhase = ''
      mkdir -p $out/bin

      cp beegfs_ctl/build/beegfs-ctl $out/bin
      cp beegfs_fsck/build/beegfs-fsck $out/bin
      cp beegfs_utils/scripts/beegfs-check-servers $out/bin
      cp beegfs_utils/scripts/beegfs-df $out/bin     
      cp beegfs_utils/scripts/beegfs-net $out/bin     
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

