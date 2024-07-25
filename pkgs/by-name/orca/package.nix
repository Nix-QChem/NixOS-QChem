{ lib, stdenv, requireFile, autoPatchelfHook, makeWrapper
, openmpi, openssh, xtb, enableAvx2 ? true
} :

stdenv.mkDerivation {
  pname = "orca";
  version = "6.0.0";

  src = if enableAvx2
  then requireFile {
    name = "orca_6_0_0_linux_x86-64_avx2_shared_openmpi416.tar.xz";
    sha256 = "sha256-AsISlO/nsbch4my5D5juFa1oLQKAcgG30hff5nkFov0=";
    url = "https://orcaforum.kofo.mpg.de/app.php/portal";
  } else requireFile {
    name = "orca_6_0_0_linux_x86-64_shared_openmpi416.tar.xz";
    sha256 = "sha256-IZvR3rbWSmPLckcZJsuBZly7zewZ+clUl2G+Z9SaKcY=";
    url = "https://orcaforum.kofo.mpg.de/app.php/portal";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ openmpi stdenv.cc.cc.lib ];

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/share/doc/orca

    cp autoci_* $out/bin
    cp openCOSMORS $out/bin
    cp orca_* $out/bin
    cp orca $out/bin
    cp otool_* $out/bin

    cp -r CompoundScripts $out/bin
    cp -r datasets $out/bin

    cp -r lib/* $out/lib/.

    cp *.pdf $out/share/doc/orca

    wrapProgram $out/bin/orca --prefix PATH : '${lib.getBin openmpi}/bin:${lib.getBin openssh}/bin'

    ln -s ${lib.getBin xtb}/bin/xtb $out/bin/otool_xtb
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    cat << EOF > inp
    ! RHF STO-3G NORI PATOM
    %output
    PrintLevel=Normal
    Print[ P_MOs         ] 1
    end
    %pal nprocs 4 #### no. of procs #####
    end
    %maxcore 1000
    #### give all coords in Angstrom #######
    * xyz 0 1
    O       0.000000  0.000000  0.000000
    H       0.758602  0.000000  0.504284
    H       0.758602  0.000000 -0.504284
    *
    EOF

    export OMPI_MCA_rmaps_base_oversubscribe=1
    $out/bin/orca inp > log

    echo "Check for successful run:"
    grep "ORCA TERMINATED NORMALLY" log
    echo "Check for correct energy:"
    grep "FINAL SINGLE POINT ENERGY" log | grep 74.880174
  '';

  passthru = { mpi = openmpi; };

  meta = with lib; {
    description = "Ab initio quantum chemistry program package";
    homepage = "https://orcaforum.kofo.mpg.de/";
    license = licenses.unfree;
    maintainers = [ maintainers.markuskowa maintainers.sheepforce ];
    platforms = [ "x86_64-linux" ];
  };
}
