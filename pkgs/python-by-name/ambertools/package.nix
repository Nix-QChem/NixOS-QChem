{ buildPythonPackage
, lib
, requireFile
, makeWrapper
, cython
  # Python dependencies
, numpy
, scipy
, matplotlib
, setuptools
, pandas
, numba
, gemmi
, biopython
, rich
, freesasa
, scikit-learn
, sympy
, pydantic
, psutil
, networkx
, distutils
  # Native dependencies
, gfortran
, cmake
, readline
, perl
, flex
, bison
, zlib
, boost186
, netcdffortran
, fftw
, blas
, lapack
, protobuf
, plumed
, apbs
, arpack
, runtimeShell
, autoPatchelfHook
}:

buildPythonPackage rec {
  pname = "AmberTools";
  version = "26";

  src = requireFile {
    name = "ambertools${version}.tar.bz2";
    sha256 = "sha256-XUbu88K7fVv56MDDit00QG6mfj8OQJesnRHYpURTjJw=";
    url = "https://ambermd.org/AmberTools.php";
  };

  patches = [
    # Keep nix dependencies. The build system assumes it provides all packages,
    # including stuff like numpy, otherwise, itself.
    ./pythonpath-keep-env.patch

    # Remove a pip install from a subpackage. We provide these deps ourselves.
    ./pype-resp-no-pip.patch
  ];

  # Force pytraj to regenerate Cython sources from .pyx instead of using
  # pre-generated .cpp files that are incompatible with Python 3.14.
  postPatch = ''
    substituteInPlace AmberTools/src/pytraj/base_setup/build_config.py \
      --replace-fail "self.use_prebuilt = True" "self.use_prebuilt = False"
  '';

  nativeBuildInputs = [
    cmake
    gfortran
    flex
    bison
    makeWrapper
    cython
    # Fixes references to /build/ and the adds the references to $out/lib libraries
    autoPatchelfHook
  ];

  buildInputs = [
    zlib
    boost186
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
    "-DCHECK_UPDATES=OFF"
    "-DAPPLY_UPDATES=OFF"
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
    pandas
    numba
    gemmi
    biopython
    rich
    freesasa
    scikit-learn
    sympy
    pydantic
    psutil
    networkx
    distutils
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
        "residuegen"
        "respgen"
        "XrayPrep"
      ];
    in
    ''
      runHook preInstall

      make install

      # Install libnlopt.so* to $out/lib so that the RPATH entries in AmberTools binaries can find it.
      mkdir -p $out/lib
      find $NIX_BUILD_TOP -name 'libnlopt.so*' -exec cp -a {} $out/lib/ \; 2>/dev/null || true

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
            --set-default AMBERHOME $out \
            --set-default QUICK_BASIS=$out/AmberTools/src/quick/basis
        fi
      done

      runHook postInstall
    '';

  # Help autopatchelfhook to find C libs shipped with AmberTools (e.g. libcpptraj.so)
  appendRunpaths = [ "${placeholder "out"}/lib" ];

  # Multiple CPython libs have /build references. They are fixed by autopatchelfHook
  # later, so we skip this check here.
  noAuditTmpdir = true;

  # There is a force field alias to a non-existing force field in the test leaprc
  # It is shipped like this in the official tarball.
  dontCheckForBrokenSymlinks = true;

  meta = with lib; {
    description = "Tools for molecular mechanics and molecular dynamics with AMBER";
    homepage = "https://ambermd.org/AmberTools.php";
    license = with licenses; [ lgpl3 bsd3 mit asl20 gpl3Only gpl2Only ];
    platforms = platforms.linux;
  };
}
