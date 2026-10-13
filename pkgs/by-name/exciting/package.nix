{ lib
, stdenv
, fetchFromGitHub
, cmake
, gfortran
, perl
, python3
, libxslt
, runtimeShell
, blas
, lapack
, fftw
, fftwFloat
, mpi
, scalapack
, enableSgroup ? false
, sgroup
}:

stdenv.mkDerivation rec {
  pname = "exciting";
  version = "sodium.0.2";

  src = fetchFromGitHub {
    owner = "exciting";
    repo = "exciting";
    rev = version;
    hash = "sha256-M8Oyon5dbFtocIamAiepFQw06teKBQrVslU/ktC9A0s=";
  };

  outputs = [ "out" "dev" ];
  postPatch = ''
    # Remove the bundled cmake binary
    rm -r external/cmake-*

    # Do not optimize for the build machine
    substituteInPlace cmake/CompilerFlags.cmake \
      --replace-fail '-march=''${ARCH_MARCH} ' ""

    patchShebangs .
  '';

  nativeBuildInputs = [
    cmake
    gfortran
    perl
    python3
    libxslt
    mpi
  ];

  buildInputs = [
    blas
    lapack
    fftw
    fftwFloat
    scalapack
  ];

  propagatedBuildInputs = [ mpi ];
  propagatedUserEnvPkgs = [ mpi ] ++ lib.optional enableSgroup sgroup;
  passthru = { inherit mpi; };

  cmakeFlags = [
    (lib.cmakeBool "MPI" true)
    (lib.cmakeBool "OMP" true)
    (lib.cmakeBool "SCALAPACK" true)
    (lib.cmakeFeature "SCALAPACK_ROOT" "${scalapack}")
    (lib.cmakeFeature "FFTW3_ROOT" "${lib.getDev fftw}")
    (lib.cmakeBool "UNIT_TESTS" false)
  ];

  enableParallelBuilding = true;

  postInstall = ''
    mkdir -p $out/share/exciting/species
    cp ../species/* $out/share/exciting/species/

    # Replace upstream's symlink with a wrapper that resolves $EXCITINGROOT
    rm $out/bin/exciting
    mv $out/bin/exciting_mpismp $out/bin/.exciting_mpismp-wrapped

    cat > $out/bin/exciting_mpismp <<EOF
    #!${runtimeShell}
    if [ -n "\$1" ]; then
      sed 's:\$EXCITINGROOT:$out/share/exciting:' \$1 > \$1s
      exec $out/bin/.exciting_mpismp-wrapped \$1s
    else
      printf "Missing input file"
      exit 1
    fi
    EOF

    chmod +x $out/bin/exciting_mpismp

    # The MPI/OpenMP binary also runs without mpirun
    ln -s $out/bin/exciting_mpismp $out/bin/exciting_smp
    ln -s $out/bin/exciting_mpismp $out/bin/exciting
  '';

  meta = with lib; {
    description = "Full-potential all-electron density-functional-theory package";
    homepage = "https://exciting-code.org";
    license = with licenses; [ gpl2Plus gpl3Only bsd3 bsd0 ];
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}
