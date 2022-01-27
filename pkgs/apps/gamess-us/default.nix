{ stdenv, lib, makeWrapper, fetchFromGitLab, requireFile, gfortran, writeTextFile, cmake, perl
, tcsh, mpi, blas, hostname, openssh, gnused, libxc, ncurses
, enableMpi ? true
}:
assert
  lib.asserts.assertMsg
  (builtins.elem blas.passthru.implementation [ "mkl" "openblas" ])
  "The BLAS providers can be either MKL or OpenBLAS.";

assert
  lib.asserts.assertMsg
  (blas.isILP64)
  "A 64 bit integer implementation of BLAS is required.";

let target = if enableMpi then "mpi" else "sockets";
in stdenv.mkDerivation rec {
  pname = "gamess-us";
  version = "2021R2P1";

  # The website always provides "gamess-current.tar.gz". However, we expect the file to be renamed,
  # to a more reasonable name.
  src = requireFile rec {
    name = "${pname}-${version}.tar.gz";
    sha256 = "36a07e3567eec3b804fca41022b45588645215ccf4557d5176fb69d473b9521c";
    url = "https://www.msg.chem.iastate.edu/gamess/download.html";
  };

  patches = [
    # Launcher scripts, which also contains settings, such as MPI locations and data paths
    ./rungms.patch
    # Adaptions to a more nix-like directory structure
    ./AuxDataPath.patch
    # Link MKL dynamic libraries, instead of static
    ./mkl.patch
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
    blas
  ];

  propagatedBuildInputs = [
    tcsh
    mpi
  ];

  postPatch =
    let
      # Environment variable required by GAMESS to set correct MPI version in rungms script.
      mpiname = mpi.pname;
      mpiroot = builtins.toString mpi;
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

  # The interactive config script of gamess. Pretty standard build with MPI parallelism, but
  # without additional interfaces (such as libxc, qcengine, tinker, ...)
  configurePhase = ''
    ./config << EOF

    linux64


    ${version}
    gfortran
    ${lib.versions.majorMinor gfortran.version}

    ${blas.passthru.implementation}
    ${blas.passthru.provider}
    ${if blas.implementation == "mkl"
       then "proceed"
       else "${blas.passthru.provider}/lib"
    }

    ${if enableMpi then "${target}\n${mpi.pname}\n${mpi}" else target}
    no
    no
    no
    no
    no
    no
    no
    no
    no
    no
    no
    EOF
  '';

  makeFlags = [ "ddi" "modules" "gamess" ];

  # Of course also the installation is quite custom ... Take care of the installation.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share $out/share/gamess

    # Copy the interesting scripts and executables
    cp gamess.${version}.x rungms ${lib.strings.optionalString (!enableMpi) "ddi/ddikick.x"} $out/bin/.

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
  installCheckPhase = ''
    # MPI fixes in sandbox
    export HYDRA_IFACE=lo
    export OMPI_MCA_rmaps_base_oversubscribe=1

    $out/bin/rungms $out/share/gamess/tests/mcscf/mrpt/parallel/mc-detpt-bic-short.inp ${version} 2 2
  '';

  hardeningDisable = [ "format" ];

  passthru = { inherit mpi; };

  meta = with lib; {
    description = "GAMESS is a program for ab initio molecular quantum chemistry";
    homepage = "https://www.msg.chem.iastate.edu/gamess/index.html";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
