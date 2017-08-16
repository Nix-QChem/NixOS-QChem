{ stdenv, fetchurl, which, openssh, gcc, gfortran, 
  openmpi, atlasWithLapack, python, tcsh, bash } :
let
  version = "6.6";
in
  stdenv.mkDerivation {
    name = "nwchem-${version}";

    src = fetchurl {
      url = "http://www.nwchem-sw.org/download.php?f=Nwchem-6.6.revision27746-src.2015-10-20.tar.bz2";
      sha256 = "167pjwjdhsfqhphnraxjd20adhc3qa8ka3a2fqj4232hhd4356vv";
    };

    patches = [ ./nixos-depend.patch ];

    hardeningDisable = [ "format" ];
    nativeBuildInputs = [ gcc ];
    buildInputs = [ tcsh openssh which gfortran openmpi atlasWithLapack which python ];

    postPatch = ''
      find -type f -executable -exec sed -i "s:/bin/bash:${bash}/bin/bash:" \{} \;
      find -type f -executable -exec sed -i "s:/bin/csh:${tcsh}/bin/tcsh:" \{} \;
      find -type f -name "GNUmakefile" -exec sed -i "s:/usr/bin/gcc:${gcc}/bin/gcc:" \{} \;
      find -type f -executable -exec sed -i "s:/bin/rm:`which rm`:" \{} \;
    '';  

    meta = {
      description = "Quantum chemistry program";
      licenses = stdenv.lib.licenses.free;
    };

    enableParallelBuilding = true;

    buildPhase = ''
      export NWCHEM_TOP="`pwd`"
      export NWCHEM_MODULES="all python"
      export NWCHEM_TARGET="LINUX64"
      export BLAS_SIZE="8"
      export USE_MPI=y
      export USE_INTERNALBLAS=y
#export BLASOPT="-L${atlasWithLapack}/lib -llapack -lf77blas -lcblas -latlas"
      export BLAS_SIZE=4
      export USE_64TO32=y
      export USE_PYTHONCONFIG="y"
      export PYTHONHOME=${python}
      export PYTHONVERSION=2.7
      cd src

      echo "ROOT: $NWCHEM_TOP"
      make nwchem_config
      make 64_to_32
      make 
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
  }


