{ stdenv, fetchFromGitHub, which, openssh, gcc, gfortran, perl,
  openmpi, openblas, python, tcsh, git, bash, automake, autoconf } :
let
  version = "6.8";

  ga_src = fetchFromGitHub {
    owner = "GlobalArrays";
    repo = "ga";
    rev = "v5.6.3";
    sha256 = "0dgrli9rdxffzl0nd3998fbnlnlibx7ahid2v0nhis1r1i71k1dn";
  };
in
  stdenv.mkDerivation {
    name = "nwchem-${version}";

    src = fetchFromGitHub {
      owner = "nwchemgit";
      repo = "nwchem";
      rev = "v${version}-release";
      sha256 = "1v3gam7bg3x4lzx5n91bpr7646py54h03lzanpnq22ma7666r30r";
    };

#hardeningDisable = [ "format" ];
    nativeBuildInputs = [ gcc perl git automake autoconf ];
    buildInputs = [ tcsh openssh which gfortran openmpi openblas which python ];

    postUnpack = ''
      echo "getting GA sources"
      export srcRoot=`pwd`
      export gaSrc="$srcRoot/nwchem-v6.8-release-src/src/tools/ga-5.6.3/"
      echo $gaSrc
      mkdir -p $gaSrc
      cp -r ${ga_src}/* $gaSrc
      chmod -R u+w $gaSrc
      cd $gaSrc

      mkdir build-aux
      autoreconf -vif

      cd $srcRoot
    '';

    postPatch = ''
#      find -type f -executable -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
#      find -type f -executable -exec sed -i "s:/bin/csh:${tcsh}/bin/tcsh:" \{} \;
      find -type f -name "GNUmakefile" -exec sed -i "s:/usr/bin/gcc:${gcc}/bin/gcc:" \{} \;
      find -type f -executable -exec sed -i "s:/bin/rm:rm:" \{} \;
      find -type f -name "makelib.h" -exec sed -i "s:/bin/rm:rm:" \{} \;
      patchShebangs ./

#  sed -i "/GET_TOOLS=/d" src/tools/GNUmakefilea
       sed -i "s/wget/echo/" src/tools/get-tools
       sed -i "s/wget/echo/" src/tools/get-tools-github
       alias wget='echo'
       alias curl='echo'
       touch src/tools/ga-5.6.3.tar.gz
    '';

    meta = {
      description = "Quantum chemistry program";
      licenses = stdenv.lib.licenses.free;
    };

    enableParallelBuilding = true;

    preBuild = ''
      export NWCHEM_TOP="`pwd`"
      export NWCHEM_TARGET="LINUX64"

      export ARMCI_NETWORK="MPI-MT"
      export USE_MPI=y
      export USE_MPIF=y
      export LIBMPI="-lmpi_f90 -lmpi_f77 -lmpi -ldl -Wl,--export-dynamic -lnsl -lutil"

      export NWCHEM_MODULES="all python"
      export MRCC_METHODS=TRUE

      export USE_PYTHONCONFIG="y"
      export USE_PYTHON64="n"
      export PYTHONLIBTYPE="so"
      export PYTHONHOME=${python}
      export PYTHONVERSION=2.7

      export BLASOPT="-L${openblas}/lib -lopenblas"

      export BLAS_SIZE="8"
#      export USE_INTERNALBLAS=y
#      export BLAS_SIZE=4
#export USE_64TO32=y
      cd src

      echo "ROOT: $NWCHEM_TOP"
      make nwchem_config
#      make 64_to_32
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp $NWCHEM_TOP/bin/LINUX64/nwchem $out/bin

      cp -r $NWCHEM_TOP/src/data $out/share

      cp -r $NWCHEM_TOP/src/basis/libraries $out/share

      cp -r $NWCHEM_TOP/QA $out/share
    '';

    checkPhase = ''
      cd $NWCHEM_TOP/QA
      ./doqmtests.mpi
    '';

    doCheck=true;
  }


