{ stdenv, lib, makeWrapper, fetchFromGitLab, requireFile, mpiCheckPhaseHook, gfortran, cmake, perl
, tcsh, mpi, openblas, hostname, openssh, gnused, ncurses
, enableMpi ? true
}:

let target = if enableMpi then "mpi" else "sockets";
in stdenv.mkDerivation rec {
  pname = "gamess-us";
  version = "2024R2P1";

  # The website always provides "gamess-current.tar.gz". However, we expect the file to be renamed,
  # to a more reasonable name.
  src = requireFile {
    name = "${pname}-${version}.tar.gz";
    sha256 = "sha256-mQUe3sPLh2aCLh93t7Qc+fLULOYeZnE+S1El9zV83qk=";
    url = "https://www.msg.chem.iastate.edu/gamess/download.html";
  };

  patches = [
    # Launcher scripts, which also contains settings, such as MPI locations and data paths
    ./rungms.patch
    # Adaptions to a more nix-like directory structure
    ./AuxDataPath.patch
    # Link OpenBLAS dynamic libraries, instead of static
    ./openblas.patch
    # Recognize gcc-12.4 as a valid compiler
    ./gcc-config.patch
    # Use mpiexec in OpenMPI instead of orterun
    ./openmpi.patch
  ];

  nativeBuildInputs = [
    makeWrapper
    cmake
    perl
    hostname
    gnused
    ncurses
  ];

  buildInputs = [
    gfortran
    openblas
  ];

  propagatedBuildInputs = [
    tcsh
    mpi
  ];

  postPatch =
    let
      # Environment variable required by GAMESS to set correct MPI version in rungms script.
      mpiname = mpi.pname;
      mpiroot = "${mpi}";
    in ''
      # patchshebangs does not patch /bin/csh, as it does not recognise those. Also /bin/csh appears
      # in more locations than just shebangs
      find . -type f -exec sed -i "s!/bin/csh!${tcsh}/bin/tcsh!g" {} \;

      # Increase the maximum numbers of CPUs per node and maximum number of Nodes to a more reasonable
      # value for DDI
      substituteInPlace ddi/compddi --replace "set MAXCPUS=32" "set MAXCPUS=256"

      # Prepare the rungms script -> replace references to @version@ and @out@
      export mpiname=${mpiname}
      export mpiroot=${mpiroot}
      export target=${target}
      substituteAllInPlace rungms

      # Make config accept dynamic OpenBLAS
      substituteInPlace config --replace "libopenblas.a" "libopenblas.so"
      substituteInPlace lked --replace "libopenblas.a" "libopenblas.so"
    '';

  # Needed to build with gcc-14
  env.NIX_CFLAGS_COMPILE = "-Wno-error=int-conversion";

  # The interactive config script of gamess. Pretty standard build with MPI parallelism, but
  # without additional interfaces (such as libxc, qcengine, tinker, ...)
  configurePhase =
    let configAnswers = lib.strings.concatStringsSep "\n" ([
          ""                                         # Skip informative prompt
          "linux64"                                  # Target machine is a amd64 linux. Actually I don't see why this wouldn't fit other architectures as well.
          ""                                         # Skip two more prompts
          ""
          version                                    # A version string, which will determine the name of the gamess executable.
          ""                                         # Are you building for a specific HPC machine? No.
          "gfortran"                                 # The fortran compiler we are using.
          (lib.versions.majorMinor gfortran.version) # Version of gfortran. GAMESS uses different optimisation flags for different versions and becomes numerically wrong if we lie here
          ""                                         # Skip another prompt
          "openblas"                                 # BLAS implementation that we are using as a name
          "${openblas}/lib"                          # Path to the BLAS installation
          ""                                         # Skip another prompt and proceed to network setup
          target                                     # The target is either sockets or MPI.
        ] ++ lib.optionals enableMpi [               # If MPI was selected it ask for the MPI installation details
          mpi.pname                                  # The MPI implementation
          "${lib.getDev mpi}"                        # Path to the MPI installation
        ] ++ [                                       # Activation of optional plugins, such as active space CC, LibXC, ...
          "no"
          "no"
          "no"
          "no"
          "no"
          "no"
          "no"
          "no"
          "no"
          "no"
          "no"
        ]);
    in ''
      ./config << EOF
      ${configAnswers}
      EOF
  '';

  makeFlags = [ "ddi" "modules" "gamess" ];

  # Of course also the installation is quite custom ... Take care of the installation.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share $out/share/gamess

    # Copy the interesting scripts and executables
    cp gamess.${version}.x rungms ${lib.strings.optionalString (!enableMpi) "$(find -name ddikick.x -type f -executable)"} $out/bin/.

    # Copy the file definitions to share
    cp gms-files.csh $out/share/gamess/.

    # Copy auxdata, which contains parameters and basis sets
    cp -r auxdata $out/share/gamess/.

    # Copy the test files
    cp -r tests $out/share/gamess/.

    runHook postInstall
  '';

  # Patch the entry point to fit this systems needs for running an actual calculation.
  postFixup =
    let binSearchPath = lib.strings.makeSearchPath "bin" [ openssh mpi tcsh hostname ];
    in ''
      wrapProgram $out/bin/rungms \
        --set-default SCRATCH "/tmp" \
        --set-default OMP_NUM_THREADS 1 \
        --prefix PATH : ${binSearchPath}
    '';

  doInstallCheck = true;

  nativeCheckInputs = [
    mpiCheckPhaseHook
    openssh
  ];

  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/rungms $out/share/gamess/tests/mcscf/mrpt/parallel/mc-detpt-bic-short.inp ${version} 1 2
    runHook postInstallCheck
  '';

  hardeningDisable = [ "format" ];

  passthru = { inherit mpi; };

  meta = with lib; {
    description = "GAMESS is a program for ab initio molecular quantum chemistry";
    homepage = "https://www.msg.chem.iastate.edu/gamess/index.html";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "rungms";
    maintainers = [ maintainers.sheepforce ];
  };
}
