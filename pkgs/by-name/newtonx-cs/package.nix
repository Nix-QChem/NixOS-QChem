{ stdenv
, lib
, fetchFromGitLab
, gfortran
, blas
, lapack
, cioverlap
, perl
}:

let
  newtonx = import ../newton-x/common.nix { inherit fetchFromGitLab; };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "newtonx-cs";
  inherit (newtonx) version src;

  sourceRoot = "source/NX-CS";

  nativeBuildInputs = [ gfortran ];

  buildInputs = [ blas lapack perl ];

  dontConfigure = true;

  env.BLAS_DIR = "${lib.getLib blas}/lib";
  env.LAPACK_DIR = "${lib.getLib lapack}/lib";

  postPatch = ''
    # Fix all makefiles for dynamic linking and nix compatibility:
    # 1. Remove -static flag (varies per makefile: "-static -lpthread" or "-static -fbacktrace...")
    # 2. Change gfortran-10 to gfortran
    # 3. Replace 'clear' command (not available in sandbox)
    substituteInPlace \
      source/lib/makefile \
      source/moldyn/makefile \
      source/initcond/makefile \
      source/tools/makefile \
      source/cioverlap/nx/makefile \
      source/cioverlap/od-cioverlap/makefile \
      --replace "gfortran-10" "gfortran" \
      --replace " -static" "" \
      --replace "	clear" "	true"
  '';

  buildPhase = ''
    runHook preBuild

    # 1. Build lib (Fortran library modules)
    cd source/lib
    make library FCMPLR=gfortran FFLAGS="-lpthread"
    cd ../..

    # 2. Build tools
    cd source/tools
    make all FCMPLR=gfortran FFLAGS="-lpthread" \
      LDFLAGS="-L$LAPACK_DIR -L$BLAS_DIR -llapack -lblas -lpthread" \
      LDLIBS="-llapack -lblas -lpthread"
    cd ../..

    # 3. Build initcond
    cd source/initcond
    make all FCMPLR=gfortran FFLAGS="-lpthread"
    cd ../..

    # 4. Build moldyn
    cd source/moldyn
    make all FCMPLR=gfortran FFLAGS="-lpthread" \
      LDFLAGS="-L$LAPACK_DIR -L$BLAS_DIR -llapack -lblas -lpthread" \
      LDLIBS="-llapack -lblas -lpthread"
    # Rename amodel to analytical.model (as upstream does)
    ln -s amodel EXE_moldyn/analytical.model
    cd ../..

    # 5. Build cioverlap/nx (cio_end, lcao)
    cd source/cioverlap/nx
    make all FCMPLR=gfortran FFLAGS="-lpthread"
    cd ../../..

    # 6. Build cioverlap-od
    cd source/cioverlap/od-cioverlap
    make all FCMPLR=gfortran \
      FFLAGS="-fbacktrace -O3 -frecursive" \
      LDFLAGS="-L$LAPACK_DIR -L$BLAS_DIR" \
      LDLIBS="-llapack -lblas"
    cd ../../..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/bin/lib

    # Install Fortran executables from tools
    for prog in aninp nx2a2 nx2gamess nx2bagel nx2int nx2tm nx2cp2k rwprop statistics tm2nx cp2k2nx xyz2nx importance_sampling fragments chk_diss; do
      [ -f source/tools/EXE_tools/$prog ] && cp source/tools/EXE_tools/$prog $out/bin/
    done

    # Install Fortran executables from initcond
    for prog in do_cis mk_qvector weight initqp writeall readall raninicon; do
      [ -f source/initcond/EXE_initcond/$prog ] && cp source/initcond/EXE_initcond/$prog $out/bin/
    done

    # Install Fortran executables from moldyn
    for prog in inp moldyn01 moldyn02 moldyn03 moldyn04 typeofdyn write_pair md2tm md2col md2cp2k phase_correction interpol escalar escalar_pntch polint polint_gamma polint_gamma_model_2 grep_results_from_ref model_cs_fssh thermostat sh lemo analytical.model; do
      [ -f source/moldyn/EXE_moldyn/$prog ] && cp source/moldyn/EXE_moldyn/$prog $out/bin/
    done

    # Install cio_end and lcao from cioverlap/nx
    for prog in cio_end lcao; do
      [ -f source/cioverlap/nx/EXE_nxcio/$prog ] && cp source/cioverlap/nx/EXE_nxcio/$prog $out/bin/
    done

    # Install cioverlap.od from od-cioverlap
    [ -f source/cioverlap/od-cioverlap/EXE_ciood/cioverlap ] && cp source/cioverlap/od-cioverlap/EXE_ciood/cioverlap $out/bin/cioverlap.od

    # Install Perl scripts and other tools from tools/
    cp source/tools/*.pl $out/bin/
    cp source/tools/arrow $out/bin/
    cp source/tools/plot $out/bin/
    cp source/tools/dftb2nx $out/bin/
    cp source/tools/nx2dftb $out/bin/
    cp source/tools/dftb2xyz $out/bin/
    cp source/tools/nx2xyz $out/bin/
    cp source/tools/nxinp $out/bin/
    cp source/tools/version.txt $out/bin/
    cp source/tools/icinp $out/bin/

    # Install Perl and Python scripts from initcond/
    cp source/initcond/*.pl $out/bin/
    cp source/initcond/*.py $out/bin/

    # Install Perl and Python scripts from moldyn/
    cp source/moldyn/*.pl $out/bin/
    cp source/moldyn/*.py $out/bin/
    cp source/moldyn/md2hybrid $out/bin/
    cp source/moldyn/inclusion_sphere $out/bin/

    # Install cioverlap Perl scripts
    cp source/cioverlap/nx/*.pl $out/bin/

    # Install Perl modules to bin/lib/
    cp source/lib/*.pm $out/bin/lib/

    # Create cioverlap-64 directory with symlinks to standalone cioverlap
    mkdir -p $out/bin/cioverlap-64
    for prog in cioverlap cioverlap.od bin2matrix bin2smatrix bin4index cis_casida cis_slatergen civecconsolidate matrix2bin readsifs; do
      [ -f ${cioverlap}/bin/$prog ] && ln -s ${cioverlap}/bin/$prog $out/bin/cioverlap-64/$prog
    done

    chmod +x $out/bin/*
    patchShebangs $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "Newton-X CS: surface hopping molecular dynamics (classic Fortran code)";
    homepage = "https://gitlab.com/light-and-molecules/newtonx-cs";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
})
