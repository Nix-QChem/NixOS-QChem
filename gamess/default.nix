#
# This derviation can be compiled with MKL or atlas
#
# TODO: * Add test to output and fix python scripts
#       * Add check routine acutally running the test
#

{ stdenv, requireFile, nettools, which,
  gfortran, tcsh, mathlib , useMkl ? false } : 

let
  version = "20170420";
  hurl =  http://www.msg.ameslab.gov/gamess;

  target = 
    if stdenv.system == "i686-linux" then
      "linux32"
    else if stdenv.system == "x86_64-linux" then
      "linux64"
    else
      throw "This derivation only implements i686 or x86_64 linux";
in

stdenv.mkDerivation rec {
  name = "gamess-" + version;
  filename = name + ".tar.gz";
  withMKL = if useMkl then "yes" else "no";

  src = requireFile {
     name = filename;
     url = hurl;
     message = ''
	This nix expression requires the file ${filename} to be present.
	Go to ${hurl} and obtain a copy of GAMESS.
	Place the file in the nix store with nix-store --add-fixed sha256 ${filename}
	'';
     sha256 = "19wdw5djxazvd1yjk1v8v0ms5cxzb84jsizc8xd7sg998zhlfrva";
  };


  patchPhase = ''
     csh=`which tcsh`
     gver=`gfortran -dumpversion | sed "s/.[0-9]$//"`

     # There's a csh in nix but it's binary is tcsh
     find -type f -executable -exec sed -i "s:/bin/csh:$csh:" \{} \;

     gver="5.3"
     root=`pwd`


     # Patch the interactive config file
     substituteInPlace ./config --replace 'GMS_PATH=$<'  "GMS_PATH=$root" \
                                --replace 'GMS_BUILD_DIR=$<' "GMS_BUILD_DIR=$root/build" \
                                --replace 'GMS_TARGET=$<' GMS_TARGET=${target} \
                                --replace 'GMS_FORTRAN=$<' "GMS_FORTRAN=gfortran" \
				--replace 'GMS_GFORTRAN_VERNO=$<' GMS_GFORTRAN_VERNO=$gver
     substituteInPlace ./config --replace 'GMS_DDI_COMM=$<' "GMS_DDI_COMM=sockets" \
                                --replace 'GMS_PHI=$<' "GMS_PHI=no" \
                                --replace 'GMS_SHMTYPE=$<' "GMS_SHMTYPE=sysv" \
                                --replace 'GMS_OPENMP=$<' "GMS_OPENMP=no" 

      # patch for MKL/atlas				
      if [ "${withMKL}" == "yes" ]; then
         substituteInPlace ./config --replace 'GMS_MATHLIB=$<' "GMS_MATHLIB=mkl" \
                                    --replace 'mklhead=$<' "mklhead=${mathlib}" \
	      	                    --replace 'version=$<' 'version=proceed'

      else
         substituteInPlace ./config --replace 'GMS_MATHLIB=$<' "GMS_MATHLIB=atlas" \
                                    --replace 'GMS_MATHLIB_PATH=$<' "GMS_MATHLIB_PATH=${mathlib}/lib"  
      fi			  

     # Answer 'no' for LIBCCHEM feature 
     sed -i '1629s/\$</no/' ./config
    
     # remove all remaining prompts
     substituteInPlace ./config --replace 'reply=$<'  "" 
     substituteInPlace ./config --replace 'tput clear'  "" 

     # Fix the linker script for MKL
     sed -i '539s/-Wl/-ldl -Wl/' ./lked

     # patch rungms
     sed -i "s:set GMSPATH=/u1/mike/gamess:set GMSPATH=$out/bin:" rungms
     sed -i '64d;65d' rungms # delete SCR and USRSCR -> needs to be set by the user

     # patch gms-files.csh
     sed -i "s:\$GMSPATH/auxdata:$out/share/auxdata:" gms-files.csh

     '';
 buildPhase = ''
    cd build
    make ${if enableParallelBuilding then "-j$NIX_BUILD_CORES -l$NIX_BUILD_CORES" else ""}
     '';

 configurePhase = ''
 	./config
     '';

  installPhase = ''
     mkdir -p $out/bin
     cp ../rungms $out/bin
     cp ../gms-files.csh $out/bin

     cp -a *.x $out/bin

     mkdir -p $out/share

     cp install.info $out/share # keep it for documentation purposes
     cp -a ../auxdata $out/share
     '';


  enableParallelBuilding = true;

  buildInputs = [ gfortran tcsh ];
  nativeBuildInputs = [ which nettools mathlib ]; # BLAS/LAPACK is linked statically

  meta = {
     description = "Quantum chemistry program supporting HF/CI/MP/CC";
     homepage    =  http://www.msg.ameslab.gov/gamess;
     license = stdenv.lib.licences.unfree;
     platforms = [ "x86_64-linux" ]; 
  };
}

