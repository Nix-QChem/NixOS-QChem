{ stdenv, lib, writeText, localFile, python27, perl, gfortran } :

let
  version = "8.4.17";

  platformcnf = writeText "platform.cnf" ''
    MCTDH_VERSION="${with stdenv.lib.versions; major version + minor version}"
    MCTDH_PLATFORM="x86_64"
    MCTDH_COMPILER="gfortran"
    MCTDH_GNU_COMPILER="gfortran-64"
    MCTDH_GFORTRAN=gfortran
    MCTDH_GFORTRAN_VERSION="${lib.getVersion gfortran}"
  '';

in stdenv.mkDerivation {
  name = "mctdh-${version}";

  src = localFile {
    website = "";
    srcfile = "mctdh84.17.tgz";
    sha256 = "0p6dlpf0ikw6g8m3wsvda17ppcqb0nqijnx4ycy81vwdgx1fz8a5";
  };

  nativeBuildInputs = [ ];
  buildInputs = [ gfortran python27 perl ];

  postPatch = ''
    patchShebangs ./bin
    patchShebangs ./install

    # fix absoulte paths names
    find bin/ -type f -exec sed -i 's:/bin/mv:mv:' \{} \;
    find bin/ -type f -exec sed -i 's:/bin/rm:rm:' \{} \;
    find bin/ -type f -exec sed -i 's:/bin/mkdir:mkdir:' \{} \;
    find install/ -type f -exec sed -i 's:/bin/mv:mv:' \{} \;
    find install/ -type f -exec sed -i 's:/bin/rm:rm:' \{} \;
    find install/ -type f -exec sed -i 's:/bin/mkdir:mkdir:' \{} \;

    # remove build date
    sed -i 's:\$(date):none:' install/install_mctdh

    # fix the include dir for operators
    sed -i "s:\(mctdh[1-3]=\`echo \)\$MCTDH_DIR:\1$out/share/mctdh:" install/install_mctdh
  '';

  configurePhase = ''
    cp ${platformcnf} install/platform.cnf.priv
    cp install/compile.cnf_le install/compile.cnf
  '';



  buildPhase = ''
    mkdir utils
    cp -r bin/* utils/

    echo -e "n\nn\ny\nn\ny\n" | install/install_mctdh
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/mctdh

    cp -r operators $out/share/mctdh
    cp -r source/surfaces $out/share/mctdh

    cp -r utils/* $out/bin
    cp bin/binary/x86_64/* $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Multi configuration time dependent hartree dynamics package";
    homepage = https://www.pci.uni-heidelberg.de/cms/mctdh.html;
    license = licenses.unfree;
    maintainers = [ maintainers.markuskowa ];
    platforms = [ "x86_64-linux" ];
  };
}

