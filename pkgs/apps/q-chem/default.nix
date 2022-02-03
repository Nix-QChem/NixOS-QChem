{ stdenv, lib, writeTextFile, q-chem-installer, openssh, makeWrapper
, qchemLicensePath ? null
}:

assert
  lib.asserts.assertMsg
  (qchemLicensePath != null)
  "A Q-Chem license is required to run Q-Chem";

let
  wrapperArgs = [
    "--set QC $out"
    "--set QCPLATFORM LINUX_Ix86_64"
    "--set QCMPI seq"
    "--set QCRSH ssh"
    "--set-default QCSCRATCH /tmp"
    "--set-default QCAUX $out/qcaux"
    "--prefix PATH : ${openssh}/bin"
  ];
in stdenv.mkDerivation {
  name = "${q-chem-installer.qchemInit.pname}-${q-chem-installer.qchemInit.version}";

  nativeBuildInputs = [ makeWrapper ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/{bin,exe,qcaux/license}

    BINS=$(find ${q-chem-installer.qchemInit}/bin -type f -executable)
    BINS_L=$(find ${q-chem-installer.qchemInit}/bin -type l)
    EXES=$(find ${q-chem-installer.qchemInit}/exe -type f -executable)
    EXES_L=$(find ${q-chem-installer.qchemInit}/exe -type l)

    # Symlink all files, that are not executables
    ln -s ${q-chem-installer.qchemInit}/{config,samples,share,version.txt} $out/.
    ln -s $(find ${q-chem-installer.qchemInit}/qcaux -maxdepth 1 -not -name "license") $out/qcaux/.

    # Install the license file
    echo '${builtins.readFile qchemLicensePath}' > $out/qcaux/license/qchem.license.dat

    # Make a wrapper around files in bin
    for i in $BINS; do makeWrapper $i $out/bin/$(basename $i) ${builtins.toString wrapperArgs}; done

    # Same for files in exes
    for i in $EXES; do makeWrapper $i $out/exe/$(basename $i) ${builtins.toString wrapperArgs}; done

    # Additional loops to preserve symlink structures in bin and exe
    for l in $BINS_L; do
      ln -s $out/bin/$(basename $(readlink -f $l)) $out/bin/$(basename $l)
    done
    for l in $EXES_L; do
      ln -s $out/exe/$(basename $(readlink -f $l)) $out/exe/$(basename $l)
    done
  '';

  meta = q-chem-installer.qchemInit.meta;
}
