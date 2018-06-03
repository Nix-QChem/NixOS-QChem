{ stdenv, localFile, zlib, cpio, curl, which
, srcurl ? null
} :
let
  version = "2017.3.196";
  url = https://software.intel.com/en-us/mkl;
  filename = "l_mkl_" + version + ".tgz";

  rpath = stdenv.lib.makeLibraryPath [
     zlib
     ] + ":${stdenv.cc.cc.lib}/lib64";
in
stdenv.mkDerivation {
  name = "mkl-" + version;

  src = localFile {
     srcfile = filename;
     website = url;
     sha256 = "1jpiam010kpyr4wnav2ah4y2dfzj4m7k064qih9xcr511y3rawpx";
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
      echo "PSET_INSTALL_DIR=`pwd`/dummy" >> install.cfg  # We install into a dummy directory
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

     mkdir -p $out/lib
     cp -a dummy/lib/* $out/lib
     cp -a dummy/mkl/* $out
     cp -a dummy/mkl/lib/intel64/* $out/lib

     # remove the 32bit libraries, this is the 64bit version
     rm -r $out/lib/ia32*

     mkdir -p $out/doc
     cp -a dummy/documentation_*/ $out/doc
     cp -a dummy/samples_*/ $out/doc
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

      fixBinaries "$out/lib/intel64" "$out/lib/intel64:${rpath}"
      fixBinaries "$out/benchmarks" "$out/lib/intel64:${rpath}"
      fixBinaries "$out/tools" "$out/lib/intel64:${rpath}"
      fixBinaries "$out/lib/mic" "$out/lib/mic:${rpath}"  # not sure if this is the right thing

     '';

  meta = {
    description = "Intel Math Kernel Library (MKL)";
    platforms = [ "x86_64-linux" ];
    maintainers = [ "Markus Kowalewski <markus.kowalewski@gmail.com>" ];
    unfree = true;
  };
}


