{ stdenv, requireFile, zlib, cpio, curl, which } :
let 
  version = "2017.3.196";
  url = https://software.intel.com/en-us/mkl;
  filename = "l_mpi_" + version + ".tgz";

  rpath = stdenv.lib.makeLibraryPath [
     zlib
     ] + ":${stdenv.cc.cc.lib}/lib64";
in
stdenv.mkDerivation rec {
  name = "impi-" + version;

  src = requireFile {
     name = filename;
     url = url;
     message = ''
	This nix expression requires the file ${filename} to be present.
	Go to ${url} and obtain a copy of MKL.
	Place the file in the nix store with nix-store --add-fixed sha256 ${filename}
	'';
     sha256 = "1w47zgkr1j21w5x78af9xkal5wvpml3ja7kyrryd4gxxbfyfznfs";
  };

  nativeBuildInputs = [ zlib cpio which curl ];

  prePatch = ''
      # patch installer binaries     
      INTERP=$(cat $NIX_CC/nix-support/dynamic-linker)
      RPATH="${rpath}"
      installer=pset/32e/install
      patchelf --set-interpreter "$INTERP" $installer
      oldRPATH=$(patchelf --print-rpath "$installer")
      patchelf --set-rpath "''${oldRPATH:+$oldRPATH:}$RPATH" $installer

      # Create the install.cfg file
      echo "ACCEPT_EULA=accept" > install.cfg
      echo "CONTINUE_WITH_OPTIONAL_ERROR=yes" >> install.cfg
      echo "PSET_INSTALL_DIR=$out" >> install.cfg  # We install into a dummy directory
      echo "CONTINUE_WITH_INSTALLDIR_OVERWRITE=yes" >> install.cfg
      echo "COMPONENTS=ALL" >> install.cfg
      echo "PSET_MODE=install" >> install.cfg
      echo "SIGNING_ENABLED=yes" >> install.cfg
      echo "ARCH_SELECTED=INTEL64" >> install.cfg
     '';

  installPhase = ''

     HOME=`pwd`/tmpdir
     mkdir -p tmpdir 
     mkdir -p downloads

     ./install.sh -s install.cfg --user-mode --t tmpdir -D downloads

     # install to out and move it back to dummy,
     # spares us the pain of fixing paths in the scripts later
     mkdir dummy
     mv $out/* dummy 

     mpidir="dummy/compilers_and_libraries_2017/linux/mpi/"
     mkdir -p $out/bin
     echo 1
     cp -a $mpidir/intel64/* $out
     echo 2
     cp -a $mpidir/intel64/ $out

     mkdir -p $out/share
     echo 3
     cp -a $mpidir/man $out/share
     echo 4
     cp -a $mpidir/test $out/share
     cp -a $mpidir/binding $out/share
     cp -a $mpidir/benchmarks $out/share

     mkdir -p $out/share/doc
     cp -a dummy/compilers_and_libraries_2017/linux/documentation/en/mpi/ $out/share/doc

     # and make link for the scripts and its search paths 
     ln -s $out $out/compilers_and_libraries_2017.4.196/linux/mpi
     # We ignore the MIC parts 
     '';

  dontStrip = true;

  postFixup = ''
      # Fix all binaries
      fixBinaries() {
          INTERP=$(cat $NIX_CC/nix-support/dynamic-linker)
          getType='s/ *Type: *\([A-Z]*\) (.*/\1/'
          find "$1" -type f -print | while read obj; do
              dynamic=$(readelf -S "$obj" 2>/dev/null | grep "DYNAMIC" || true)
              if [[ -n "$dynamic" ]]; then
    
                  if readelf -l "$obj" 2>/dev/null | grep "INTERP" >/dev/null; then
                      echo "patching interpreter path in $type $obj"
                      patchelf --set-interpreter "$INTERP" "$obj"
                  fi
    
                  type=$(readelf -h "$obj" 2>/dev/null | grep 'Type:' | sed -e "$getType")
                  if [ "$type" == "EXEC" ] || [ "$type" == "DYN" ]; then
    
                      echo "patching RPATH in $type $obj"
                      oldRPATH=$(patchelf --print-rpath "$obj")
                      patchelf --set-rpath "$2" "$obj"
    
                  else
    
                      echo "unknown ELF type \"$type\"; not patching $obj"
    
                fi
            fi
        done
      }

      fixBinaries "$out/lib/" "$out/lib/intel64:${rpath}"
      fixBinaries "$out/bin" "$out/lib/intel64:${rpath}"
      
     '';


  meta = {
    description = "Intel Message Passing Interface (MPI)";
    platforms = [ "x86_64-linux" ];
    maintainers = [ "Markus Kowalewski <markus.kowalewski@gmail.com>" ];
    unfree = true;
  };
}


