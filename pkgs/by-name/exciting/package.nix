{ lib
, stdenv
, fetchFromGitHub
, gfortran
, perl
, libxslt
, runtimeShell
, blas
, lapack
, mpi
, arpack
, scalapack
, enableSgroup ? false
, sgroup
}:

stdenv.mkDerivation rec {
  pname = "exciting";
  version = "neon.0.1";

  src = fetchFromGitHub {
    owner = "exciting";
    repo = "exciting";
    rev = version;
    hash = "sha256-BGJdMz/5cfrr0O4DZTx1NonJTalHqlbubMDw6Ot8QGQ=";
  };

  postPatch = ''
    patchShebangs ./build/utilities ./external/libXC/src/get_funcs.pl
  '';

  preConfigure = ''
    cat > build/make.inc <<EOF
    F90 = gfortran
    F90_OPTS = -O3 -ffree-line-length-0 -fallow-argument-mismatch -fallow-invalid-boz
    CPP_ON_OPTS = -cpp -DXS -DISO -DLIBXC
    F77 = \$(F90)
    F77_OPTS = -O3 -fallow-argument-mismatch
    FCCPP = cpp

    # Libraries
    LIB_ARP = -larpack
    # Use native blas/lapack by default
    export USE_SYS_LAPACK=true
    LIB_LPK = -llapack -lblas
    LIB_FFT = fftlib.a
    LIB_BZINT = libbzint.a
    LIBS = \$(LIB_ARP) \$(LIB_LPK) \$(LIB_FFT) \$(LIB_BZINT)

    # SMP and MPI compilers, flags and preprocessing variables
    MPIF90 = mpif90
    MPIF90_OPTS = -DMPI -DSCAL -fallow-invalid-boz
    MPI_LIBS = -lscalapack

    SMPF90_OPTS = -fopenmp -DUSEOMP
    SMPF77_OPTS = \$(SMPF90_OPTS)
    SMP_LIBS =

    BUILDMPI = true
    BUILDSMP = true
    BUILDMPISMP = true
    EOF
  '';

  enableParallelBuilding = true;

  nativeBuildInputs = [ perl libxslt gfortran ];
  buildInputs = [
    blas
    lapack
    arpack
    scalapack
  ];

  propagatedBuildInputs = [ mpi ];
  propagatedUserEnvPkgs = [ mpi ] ++ lib.optional enableSgroup sgroup;
  passthru = { inherit mpi; };

  installPhase = ''
    mkdir -p $out/bin $out/share/exciting/species

    cp species/* $out/share/exciting/species/


    cp bin/exciting_mpismp $out/bin/.exciting_mpismp-wrapped
    cp bin/exciting_smp $out/bin/.exciting_smp-wrapped

    cat > $out/bin/exciting_smp <<EOF
    #!${runtimeShell}
    if [ -n "\$1" ]; then
      sed 's:\$EXCITINGROOT:$out/share/exciting:' \$1 > \$1s

      IFS='_' read -ra VARIANT <<< "\$(basename \$0)"
      $out/bin/.exciting_\''${VARIANT[-1]}-wrapped \$1s
    else
      printf "Missing input file"
      exit 1
    fi
    EOF

    chmod +x $out/bin/exciting_smp

    ln -s $out/bin/exciting_smp $out/bin/exciting_mpismp
  '';

  meta = with lib; {
    description = "Full-potential all-electron density-functional-theory package";
    homepage = "https://exciting-code.org";
    license = with licenses; [ gpl2Plus gpl3Only bsd3 bsd0 ];
    maintainers = [ maintainers.markuskowa ];
  };
}
