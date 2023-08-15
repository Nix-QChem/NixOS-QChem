{ stdenv
, lib
, fetchurl
, fetchFromGitHub
, fetchFromGitLab
, gfortran
, cmake
, makeWrapper
, which
, openssh
, blas
, lapack
, mpi
, python3
}:

assert
lib.asserts.assertMsg
  (!blas.isILP64)
  "A 32 bit integer implementation of BLAS is required.";

let
  gen1intSrc = fetchFromGitLab {
    owner = "bingao";
    repo = "gen1int";
    rev = "1e4148ecd676761b3399801acba443925a1fee6b";
    hash = "sha256-kauwbL95TII3AVCs3H3oiy5DECqwh5JEuF/UhlBEnEE=";
  };

  pelibSrc = fetchFromGitLab {
    owner = "pe-software";
    repo = "pelib";
    rev = "19dd0e91afbd18b7c9f2611b9978b1aeaa1c19f9";
    hash = "sha256-sFgolAju05svkqozjAb2D5V0S48b9dHDOPRWD8F9fPs=";
  };

  qfitlibSrc = fetchFromGitHub {
    owner = "cstein";
    repo = "qfitlib";
    rev = "1acdc9863fdeae2cdbc7f5a599413257a095b8ad";
    hash = "sha256-GnGyWpNMrxsD9GNqGpzntDIpveDn3y4fG3m2zJbThwc=";
  };


in
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

  src = fetchurl {
    url = "https://gitlab.com/dalton/${pname}/-/archive/${version}/dalton-${version}.tar.bz2";
    hash = "sha256-Rn1BZsJrQ0jYBUoQQafDpbpz19wc2LHWof5N6ZlKE1U=";
  };

  postPatch = ''
    cp -r ${gen1intSrc}/* external/gen1int/.
    cp -r ${pelibSrc}/* external/pelib/.
    cp -r ${qfitlibSrc}/* external/qfitlib/.

    chmod -R +rwx external/*

    patchShebangs .
  '';

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
