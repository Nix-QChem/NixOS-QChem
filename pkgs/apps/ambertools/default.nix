{ buildPythonPackage
, lib
, requireFile
, makeWrapper
  # Python dependencies
, numpy
, scipy
, matplotlib
, setuptools
  # Native dependencies
, gfortran
, cmake
, readline
, perl
, flex
, bison
, zlib
, boost
, netcdf
, netcdffortran
, fftw
, blas
, lapack
, protobuf
, plumed
, apbs
, arpack
, runtimeShell
}:

buildPythonPackage rec {
  pname = "AmberTools";
  version = "24";

  src = requireFile {
    name = "AmberTools${version}.tar.bz2";
    sha256 = "sha256-UvtPszcKibfOc4otw+UTwvwZQ/3ktDgYRtnnXMSNhA8=";
    url = "https://ambermd.org/AmberTools.php";
  };

  nativeBuildInputs = [
    cmake
    gfortran
    flex
    bison
    makeWrapper
  ];

  buildInputs = [
    zlib
    boost
    blas
    lapack
    netcdffortran
    fftw
    protobuf
    plumed
    arpack
    apbs
    readline
  ];

  format = "other";

  cmakeFlags = [
    "-DCOMPILER=AUTO"
    "-DDOWNLOAD_MINICONDA=OFF"
    "-DOPENMP=ON"
    "-DTRUST_SYSTEM_LIBS=ON"
  ];

  propagatedBuildInputs = [
    perl
  ];

  dependencies = [
    numpy
    scipy
    matplotlib
    setuptools
  ];

  buildPhase = ''
    runHook preBuild

    make -j $NIX_BUILD_CORES

    runHook postBuild
  '';

  installPhase =
    let

      wrongBash = [
        "am1bcc"
        "antechamber"
        "atomtype"
        "bondtype"
        "espgen"
        "match"
        "match_atomname"
        "parmcal"
        "parmchk2"
        "prepgen"
        "reduce"
        "residuegen"
        "respgen"
        "XrayPrep"
      ];
    in
    ''
      runHook preInstall

      make install

      # Some scripts hardcode /bin/bash. Not only necessary as their shebang, but
      # some also generate bash scripts with wrong shebangs.
      for PROG in ${builtins.toString wrongBash}; do
        substituteInPlace $out/bin/$PROG --replace-fail '#!/bin/bash' '#!${runtimeShell}'
      done

      substituteInPlace $out/amber-interactive.sh --replace-fail '#! /bin/bash' '#!${runtimeShell}'

      # Avoids sourcing amber.sh before running ambertools by setting the required
      # variables via wrappers for each program.
      for PROG in $out/bin/*; do
        if [[ -f $PROG ]]; then
          wrapProgram $PROG \
            --set AMBERHOME $out \
            --set QUICK_BASIS=$out/AmberTools/src/quick/basis
        fi
      done

      runHook postInstall
    '';

  meta = with lib; {
    description = "Tools for molecular mechanics and molecular dynamics with AMBER";
    homepage = "https://ambermd.org/AmberTools.php";
    license = with licenses; [ lgpl3 bsd3 mit asl20 gpl3Only gpl2Only ];
    hydraPlatforms = [ ]; # Dont build on Hydra
    platforms = platforms.linux;
  };
}
