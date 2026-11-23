{ stdenv
, lib
, which
, hostname
, makeWrapper
, gfortran
, requireFile
, python3
, blas
, lapack
, mpi
, enableMpi ? true
}:

# Make sure to have a correct version of BLAS.
assert
lib.asserts.assertMsg
  (blas.isILP64 || blas.passthru.implementation == "mkl")
  "A 64 bit integer implementation of BLAS is required.";

assert
lib.asserts.assertMsg lapack.isILP64
  "A 64 bit integer implementation of LAPACK is required.";

let
  mpiImplementation = if mpi.pname == "mvapich" then "mpich" else mpi.pname;

in
stdenv.mkDerivation rec {
  pname = "cfour";
  version = "2.1";

  nativeBuildInputs = [ python3 makeWrapper ];

  buildInputs = [
    gfortran
    blas
    lapack
  ];

  propagatedBuildInputs = lib.optional enableMpi mpi;

  src = requireFile {
    name = "cfour-public-v${version}.tar.bz2";
    sha256 = "d88c1d7ca360f12edeca012a01ab9da7ba4792ee43d85c178f92fbe83cbdcdc4";
    url = "http://www.cfour.de/";
  };

  postPatch = ''
    patchShebangs ./config/mkdep90.py

    # Prevent continuing on to new modules upon MPI_ABORT
    substituteInPlace libr/errex.f libr/errex2.f \
      --replace-fail \
        "call MPI_ABORT(MPI_COMM_WORLD,mpierr)" \
        "call MPI_ABORT(MPI_COMM_WORLD,1,mpierr)"

    # Don't skip MPI_FINALIZE on normal exits
    substituteInPlace intprc/intproc.f \
      --replace-fail \
        $'       CALL CRAPSO\n       STOP\n' \
        $'       CALL CRAPSO\n       CALL FINALIZE("intprc")\n       STOP\n'
    substituteInPlace fillfc/fillfcdrv.f \
      --replace-fail \
        $'      call crapso\n      stop\n' \
        $'      call crapso\n      call finalize("fillfc")\n      stop\n'
    substituteInPlace prepfc2f/prepfc2f.f \
      --replace-fail \
        $'       call crapso\n       stop\n' \
        $'       call crapso\n       call finalize("prepfc2f")\n       stop\n'
    substituteInPlace sdcc/sdcc.f \
      --replace-fail \
        $'               CALL CRAPSO\n               STOP\n' \
        $'               CALL CRAPSO\n               CALL FINALIZE("sdcc")\n               STOP\n' \
      --replace-fail \
        $'         CALL CRAPSO\n         STOP\n' \
        $'         CALL CRAPSO\n         CALL FINALIZE("sdcc")\n         STOP\n'
    substituteInPlace symcor/symcor.f \
      --replace-fail \
        $'        CALL CRAPSO\n        STOP\n' \
        $'        CALL CRAPSO\n        CALL FINALIZE("symcor")\n        STOP\n'
    substituteInPlace cubic/fcubic.f \
      --replace-fail \
        $'NX,NATOM)\n\n      STOP\n' \
        $'NX,NATOM)\n\n      CALL FINALIZE("cubic")\n      STOP\n'
    # finish_cfour ends the C and C++ modules.
    substituteInPlace libr/fortran.f \
      --replace-fail \
        $'      CALL CRAPSO\n\n      END\n' \
        $'      CALL CRAPSO\n      CALL FINALIZE("finish_cfour")\n\n      END\n'

    # Fix xvip crash on stray pointer; 0 means no triples list
    substituteInPlace vip/doeomip1.f vip/doeomip2ni.f vip/edensip.f vip/edensipni.f \
      --replace-fail "IUHF,443,494,0)" "IUHF,443,494,0,0)"
    substituteInPlace vip/edensip.f vip/edensipni.f \
      --replace-fail "IUHF,460,494,2)" "IUHF,460,494,2,0)"
  '';

  preConfigure =
    let
      mpiConfig = lib.optionalString enableMpi ''
        --enable-mpi=${mpiImplementation}
        --with-mpirun="${mpi}/bin/mpiexec -np \$CFOUR_NUM_CORES"
        --with-exenodes="${mpi}/bin/mpiexec -np \$CFOUR_NUM_CORES"
      '';
    in
    ''
      configureFlagsArray+=(
        ${mpiConfig}
        FCFLAGS="-fno-optimize-strlen -fno-stack-protector -std=legacy"
        CFLAGS="-fno-optimize-strlen -fno-stack-protector"
        CXXFLAGS="-fno-optimize-strlen -fno-stack-protector"
      )
    '';

  hardeningDisable = [ "format" ];

  postFixup = ''
    for exe in $out/bin/*; do
      wrapProgram $exe \
        --set-default CFOUR_NUM_CORES 1 \
        --prefix PATH : "${lib.makeBinPath [ which hostname ]}"
    done
  '';

  passthru = lib.optionalAttrs enableMpi { inherit mpi; };

  meta = with lib; {
    description = "Specialist coupled cluster software.";
    homepage = "http://slater.chemie.uni-mainz.de/cfour/index.php";
    license = licenses.unfree;
    mainProgram = "xcfour";
    platforms = platforms.linux;
  };
}
