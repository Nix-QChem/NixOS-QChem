{ stdenv
, lib
, fetchFromGitHub
, which
, gfortran
, blas
, lapack
, fftw
, python3
, wfoverlap
, enablePysharc ? true
, hdf5
, hdf4
, netcdf
, libjpeg
}:

let
  version = "4.0.2";
  python = python3.withPackages (p: with p; [
    numpy
    openbabel-bindings
    setuptools
    scipy
    pyscf
    openmm
    numba
    h5py
    matplotlib
    pyparsing
    sympy
    pyyaml
    torch
    pytest
    ase
    opt-einsum
    threadpoolctl
  ]);

in
stdenv.mkDerivation (finalAttrs: {
  pname = "sharc";
  inherit version;

  src = fetchFromGitHub {
    owner = "sharc-md";
    repo = "sharc4";
    rev = "v${version}";
    hash = "sha256-f0qpvGWzI8I7xGMh8bzyiXEOJ69OKWbT6D2ltLbQOwQ=";
  };

  outputs = [ "out" "doc" "tests" ];

  # Needed to build with gcc-14
  env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types -Wno-error=int-conversion";

  passthru = { inherit python; };

  nativeBuildInputs = [ which gfortran ];
  buildInputs = [ blas lapack fftw python ]
    ++ lib.optionals enablePysharc ([ libjpeg hdf5 libjpeg netcdf ] ++ hdf4.all);


  postPatch = ''
    # SHARC make file (dynamics fixes)
    sed -i 's:^EXEDIR.*=.*:EXEDIR = ''${out}/bin:' source/Makefile;

    # purify output
    substituteInPlace source/Makefile \
      --replace-fail 'shell date' "shell echo $SOURCE_DATE_EPOCH" \
      --replace-fail 'shell hostname' 'shell echo nixos' \
      --replace-fail 'shell pwd' 'shell echo nixos' \
      --replace-fail '-ldf' '-lhdf'

    patchShebangs wfoverlap/scripts
  '';

  configurePhase = lib.optionalString (!enablePysharc) ''
    runHook preConfigure

    substituteInPlace source/Makefile \
      --replace-fail 'USE_PYSHARC := true' 'USE_PYSHARC := false'

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    ${lib.optionalString enablePysharc ''
      cd pysharc
      make ${builtins.toString finalAttrs.makeFlags}
      make install ${builtins.toString finalAttrs.makeFlags}
      cd ..
    ''}

    cd source
    make ${builtins.toString finalAttrs.makeFlags}

    runHook postBuild
  '';

  makeFlags = [
    "USE_COMPILER=gnu"
    "USE_LIBS=gnu"
  ];

  enableParallelBuilding = false; # Totally wrong order otherwise

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    make install ${builtins.toString finalAttrs.makeFlags}
    cd ..

    cp -u bin/* $out/bin
    cp wfoverlap/scripts/* $out/bin
    cp ${wfoverlap}/bin/wfoverlap.x $out/bin/wfoverlap_ascii.x

    mkdir -p $out/${python3.sitePackages}
    cp -r lib/* $out/${python3.sitePackages}/.

    mkdir -p $doc/share/sharc/tests
    cp doc/* $doc/share/sharc

    mkdir -p $tests/share/sharc/tests
    cp -r tests/* $tests/share/sharc/tests

    chmod +x $out/bin/*


    runHook preInstall
  '';

  postFixup = ''
    for i in $(find $out/share -name run.sh); do
      # shebang is broken (missing !)
      echo "fixing $i"
      sed -i '1s:.*:#!${stdenv.shell}:' $i
      sed -i "s:\$SHARC:$out/bin:" $i
      sed -i 's/cd \$COPY_DIR/cd $COPY_DIR\;chmod -R +w \*/' $i
    done
  '';

  meta = with lib; {
    description = "Molecular dynamics (MD) program suite for excited states";
    homepage = "https://www.sharc-md.org";
    license = licenses.gpl3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
})
