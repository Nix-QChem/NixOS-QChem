{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, which
, gfortran
, blas
, lapack
, fftw
, python3
, gnuplot
, wfoverlap
, enablePysharc ? true
, hdf5
, hdf4 # HDF4 would need Fortran support in nixpkgs
, netcdf
, libjpeg
, enableMolcas ? false
, molcas
, enableBagel ? false
, bagel
, enableOrca ? false
, orca
, enableGaussian ? false
, gaussian
, enableTurbomole ? false
, turbomole
, enableMolpro ? false
, molpro
}:

let
  version = "3.0.1";
  python = python3.withPackages (p: with p; [
    numpy
    openbabel-bindings
    setuptools
  ]);

in
stdenv.mkDerivation {
  pname = "sharc";
  inherit version;

  src = fetchFromGitHub {
    owner = "sharc-md";
    repo = "sharc";
    rev = "v${version}";
    hash = "sha256-aTFrLrp2PTZXvMI4UkXw/hAv225rADwo9W+k09td52U=";
  };

  nativeBuildInputs = [ makeWrapper which gfortran ];
  buildInputs = [ blas lapack fftw python ]
    ++ lib.optionals enablePysharc ([ libjpeg hdf5 libjpeg netcdf ] ++ hdf4.all);

  patches = [
    # Molpro tests require more memory
    ./molpro_tests.patch
  ];

  postPatch = ''
    # SHARC make file (dynamics fixes)
    sed -i 's:^EXEDIR.*=.*:EXEDIR = ''${out}/bin:' source/Makefile;

    # purify output
    substituteInPlace source/Makefile --replace 'shell date' "shell echo $SOURCE_DATE_EPOCH" \
                                      --replace 'shell hostname' 'shell echo nixos' \
                                      --replace 'shell pwd' 'shell echo nixos' \
                                      --replace '-ldf' '-lhdf'

    rm bin/*.x

    patchShebangs wfoverlap/scripts
  '';

  configurePhase = lib.optionalString enablePysharc ''
    runHook preConfigure

    substituteInPlace source/Makefile --replace 'USE_PYSHARC := false' 'USE_PYSHARC := true'

    runHook postConfigure
  '';

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/sharc/tests

    ${lib.optionalString enablePysharc ''
      cd pysharc
      make
      make install
      cd ..
    ''
    }

    cd source
    make install
    cd ..

    cp -u bin/* $out/bin
    cp wfoverlap/scripts/* $out/bin
    cp ${wfoverlap}/bin/wfoverlap.x $out/bin/wfoverlap_ascii.x

    mkdir -p $out/${python3.sitePackages}
    cp -r lib/* $out/${python3.sitePackages}/.

    cp doc/* $out/share/sharc
    cp -r tests/* $out/share/sharc/tests

    chmod +x $out/bin/*

    ln -s $out/share/sharc/tests $out/tests

    for i in $(find $out/bin -type f); do
      wrapProgram $i \
        --set SHARC $out/bin \
        --set LD_LIBRARY_PATH "$LD_LIBRARY_PATH" \
        --set HOSTNAME localhost \
        --prefix PYTHONPATH : "$out/${python3.sitePackages}" \
        ${lib.optionalString enableMolcas "--set-default MOLCAS ${molcas}"} \
        ${lib.optionalString enableBagel "--set-default BAGEL ${bagel}"} \
        ${lib.optionalString enableMolpro "--set-default MOLPRO ${molpro}/bin"} \
        ${lib.optionalString enableOrca "--set-default ORCADIR ${orca}/bin"} \
        ${lib.optionalString enableTurbomole "--set-default TURBOMOLE ${turbomole}/bin"} \
        ${lib.optionalString enableGaussian "--set-default GAUSSIAN ${gaussian}/bin"}
    done

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

  setupHooks = [
    ./sharcHook.sh
  ];

  meta = with lib; {
    description = "Molecular dynamics (MD) program suite for excited states";
    homepage = "https://www.sharc-md.org";
    license = licenses.gpl3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}
