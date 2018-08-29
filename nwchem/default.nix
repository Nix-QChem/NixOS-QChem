{ stdenv, pkgs, fetchFromGitHub, which, openssh, gcc, gfortran, perl
, mpi ? pkgs.openmpi, openblas, python, tcsh, bash
, automake, autoconf, libtool, makeWrapper 
} :

let
  version = "6.8.1";
  versionGA = "5.6.5"; # Fixed by nwchem

  ga_src = fetchFromGitHub {
    owner = "GlobalArrays";
    repo = "ga";
    rev = "v${versionGA}";
    sha256 = "19klm8hqf319pm5mgsw8ma6c7bxbkyzi8l7hlagvfw7qjanm979v";
  };

in stdenv.mkDerivation {
    name = "nwchem-${version}";

    src = fetchFromGitHub {
      owner = "nwchemgit";
      repo = "nwchem";
      rev = "${version}-release";
      sha256 = "1z91gnf1iqr2bvcqns5j3c46lyfxhvwv254siksa31wbmw5s68s2";
    };

#hardeningDisable = [ "format" ];
    nativeBuildInputs = [ perl automake autoconf libtool makeWrapper ];
    buildInputs = [ tcsh openssh which gfortran mpi openblas which python ];
    propagatedUserEnvPkgs = [ mpi ];

    postUnpack = ''
      cp -r ${ga_src}/ source/src/tools/ga-${versionGA}
      chmod -R u+w source/src/tools/ga-${versionGA}
    '';

    postPatch = ''

      find -type f -executable -exec sed -i "s:/bin/csh:${tcsh}/bin/tcsh:" \{} \;
      find -type f -name "GNUmakefile" -exec sed -i "s:/usr/bin/gcc:${gcc}/bin/gcc:" \{} \;
      find -type f -name "GNUmakefile" -exec sed -i "s:/bin/rm:rm:" \{} \;
      find -type f -executable -exec sed -i "s:/bin/rm:rm:" \{} \;
      find -type f -name "makelib.h" -exec sed -i "s:/bin/rm:rm:" \{} \;


      # Overwrite script, skipping the download
      echo -e '#!/bin/sh\n cd ga-${versionGA};autoreconf -ivf' > src/tools/get-tools-github

      patchShebangs ./

    '';

    enableParallelBuilding = true;

    preBuild = ''
      ln -s ${ga_src} src/tools/ga-${versionGA}.tar.gz


      export NWCHEM_TOP="`pwd`"
      export NWCHEM_TARGET="LINUX64"

      export ARMCI_NETWORK="MPI-MT"
      export USE_MPI=y
      export USE_MPIF=y
      export LIBMPI=`mpif90 -showme:link`
#export LIBMPI="-lmpi_f90 -lmpi_f77 -lmpi -ldl -Wl,--export-dynamic -lnsl -lutil"


      export NWCHEM_MODULES="all python"
      export MRCC_METHODS=TRUE

      export USE_PYTHONCONFIG="y"
      export USE_PYTHON64="n"
      export PYTHONLIBTYPE="so"
      export PYTHONHOME=${python}
      export PYTHONVERSION=2.7

      export BLASOPT="-L${openblas}/lib -lopenblas"

      export BLAS_SIZE="8"
      #export USE_INTERNALBLAS=y
      #export BLAS_SIZE=4
      #export USE_64TO32=y
      cd src

      echo "ROOT: $NWCHEM_TOP"
      make nwchem_config
      #make 64_to_32
    '';

    postBuild = ''
      cd $NWCHEM_TOP/src/util
      make version
      make
      cd $NWCHEM_TOP/src
      make link
    '';

    installPhase = ''
      mkdir -p $out/bin $out/share/nwchem

      cp $NWCHEM_TOP/bin/LINUX64/nwchem $out/bin/.nwchem-wrapped
      cp -r $NWCHEM_TOP/src/data $out/share/nwchem/
      cp -r $NWCHEM_TOP/src/basis/libraries $out/share/nwchem/data
      cp -r $NWCHEM_TOP/src/nwpw/libraryps $out/share/nwchem/data
      cp -r $NWCHEM_TOP/QA $out/share/nwchem

      # create wrapper
      cat << EOF > $out/bin/nwchem
      #!/bin/sh

      if [ \$# == 0 ]; then
      echo
      echo "Usage: `basename \$0` [number of procs] <input file name>"
      echo
      exit
      fi

      if [ -z "\$NWCHEM_BASIS_LIBRARY" ]; then
      NWCHEM_BASIS_LIBRARY=$out/share/nwchem/data/libraries/
      fi

      if [ \$# -gt 2 ]; then
      np=\$1; shift;
      if [ \$np == 0 ]; then
      ${mpi}/bin/mpirun $out/bin/.nwchem-wrapped \$@
      else
      ${mpi}/bin/mpirun -np \$1 $out/bin/.nwchem-wrapped \$@
      fi
      else
      $out/bin/.nwchem-wrapped \$@
      fi
      EOF

      chmod 755 $out/bin/nwchem


      cat > $out/share/nwchem/nwchemrc << EOF
      nwchem_basis_library $out/share/nwchem/data/libraries/
      nwchem_nwpw_library $out/share/nwchem//data/libraryps/
      ffield amber
      amber_1 $out/share/nwchem/data/amber_s/
      amber_2 $out/share/nwchem/data/amber_q/
      amber_3 $out/share/nwchem/data/amber_x/
      amber_4 $out/share/nwchem/data/amber_u/
      spce    $out/share/nwchem/data/solvents/spce.rst
      charmm_s $out/share/nwchem/data/charmm_s/
      charmm_x $out/share/nwchem/data/charmm_x/
      EOF
    '';

    checkPhase = ''
      cd $NWCHEM_TOP/QA
      ./doqmtests.mpi 1 fast
    '';

    doCheck=false;

    doInstallCheck = true;

    installCheckPhase = ''
      # run a simple water test
      $out/bin/nwchem $out/share/nwchem/QA/tests/h2o/h2o.nw > h2o.out
      grep "Total SCF energy" h2o.out  | grep 76.010538
    '';

    meta = {
      description = "Quantum chemistry program";
      license = {
        fullName = "Educational Community License, Version 2.0";
        url = https://github.com/nwchemgit/nwchem/blob/release-6-8/LICENSE.TXT;
      };
    };

  }


