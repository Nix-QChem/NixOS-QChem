{ stdenv, fetchurl, bash, coreutils, 
  beegfs-opentk
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

    buildInputs = [ beegfs-opentk ];
    postPatch = ''
      find -type f -executable -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -name Makefile -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
      find -type f -name "*.mk" -exec sed -i "s:/bin/true:${coreutils}/bin/true:" \{} \;
    '';

    makeFlags = [
      "-Cbeegfs_common/build"
#      "-Cbeegfs_helperd/build"
    ];

#    buildPhase = ''
#      make -j4 -C beegfs_common/build/
#      make -j4 -C beegfs_helperd/build/
#    '';

    installPhase = ''
      mkdir -p $out/bin
      
      cp beegfs_helperd/build/beegfs-helperd $out/bin
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

