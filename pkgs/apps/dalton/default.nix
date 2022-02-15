{ stdenv, lib, fetchgit, gfortran, cmake, makeWrapper
, which, openssh, blas, lapack, mpi, python3
} :

assert
  lib.asserts.assertMsg
  (!blas.isILP64)
  "A 32 bit integer implementation of BLAS is required.";

stdenv.mkDerivation rec {
  pname = "dalton";
  version = "2020.1";

  nativeBuildInputs = [
    gfortran
    cmake
    python3
    makeWrapper
  ];

  buildInputs = [
    blas
    lapack
  ];

  propagatedBuildInputs = [
    mpi
    which
  ];

  # Many submodules are required and they are not fetched by fetchFromGitLab.
  src = fetchgit  {
    url = "https://gitlab.com/dalton/dalton.git";
    rev = "9d7c5e435b75a9695d5ac8714121d12e6486149f"; # Git hash of 2020.1 as of 15.02.2022.
    sha256 = "0fk5xfnj1mrrwmwdil4qgbd1a68wrwzwqr398mz015hj2679czfd";
    deepClone = true;
  };

  postPatch = "patchShebangs .";

  FC = "mpif90";
  CC = "mpicc";
  CXX = "mpicxx";

  /*
  Cmake is required to build but adding it to the buildinputs then ignores the setup script.
  Therefore i call the script here manually but cmake is invoked by setup.
  */
  configurePhase = ''
    ./setup --prefix=$out --mpi && cd build
  '';

  enableParallelBuilding = true;

  hardeningDisable = [ "format" ];

  /*
  Dalton does not care about bin lib share directory structures and puts everything in a single
  directory. Clean up the mess here.
  */
  postInstall = ''
    mkdir -p $out/bin $out/share/dalton
    for exe in dalton dalton.x; do
      mv $exe $out/bin/.
    done

    for dir in basis tools; do
      mv $dir $out/share/dalton/.
    done

    substituteInPlace $out/bin/dalton \
      --replace 'INSTALL_BASDIR=$SCRIPT_DIR/basis' "INSTALL_BASDIR=$out/share/dalton/basis"

    rm -rf $out/dalton
  '';

  /*
  Make the MPI stuff available to the Dalton script. Direct exposure of MPI is not necessary.
  */
  postFixup = ''
    wrapProgram $out/bin/dalton \
      --prefix PATH : ${mpi}/bin \
      --prefix PATH : ${which}/bin \
      --prefix PATH : ${openssh}/bin

    wrapProgram $out/bin/dalton.x \
      --prefix PATH : ${mpi}/bin \
      --prefix PATH : ${which}/bin \
      --prefix PATH : ${openssh}/bin
  '';

  passthru = { inherit mpi; };

  meta = with lib; {
    description = "Quantum chemistry code specialised on exotic properties.";
    license = licenses.lgpl21Only;
    homepage = "https://daltonprogram.org/";
    platforms = platforms.linux;
  };
}
