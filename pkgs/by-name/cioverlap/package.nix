{ stdenv
, lib
, fetchFromGitLab
, gfortran
, gsl
, blas
, lapack
, autoconf
, automake
, libtool
}:

let
  newtonx = import ../newton-x/common.nix { inherit fetchFromGitLab; };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "cioverlap";
  inherit (newtonx) version src;

  sourceRoot = "source/CIOVERLAP";

  nativeBuildInputs = [
    gfortran
    autoconf
    automake
    libtool
  ];

  buildInputs = [
    gsl
    blas
    lapack
  ];

  dontConfigure = true;

  postPatch = ''
    # Replace get_git_version scripts that call git commands unavailable in sandbox
    substituteInPlace src/la_1.4/get_git_version \
      --replace-fail 'git describe' 'echo nixpkgs' \
      --replace-fail 'git rev-parse HEAD' 'echo nixpkgs' \
      --replace-fail 'git show -s --format=%ci $head' 'echo 2026-03-04'
    substituteInPlace src/cioverlap/get_git_version \
      --replace-fail 'git describe' 'echo nixpkgs' \
      --replace-fail 'git rev-parse HEAD' 'echo nixpkgs' \
      --replace-fail 'git show -s --format=%ci $head' 'echo 2026-03-04'
    patchShebangs src/la_1.4/get_git_version src/cioverlap/get_git_version

    # Remove -static from cioverlap-od makefile for dynamic linking
    # and replace 'clear' command (not available in sandbox)
    substituteInPlace src/cioverlap-od/makefile \
      --replace-fail '-static -fbacktrace -O3 -frecursive' '-fbacktrace -O3 -frecursive' \
      --replace-fail '	clear' '	true'
  '';

  buildPhase = ''
    runHook preBuild

    # Build LA library (autotools C++ library)
    pushd src/la_1.4
    autoreconf --install
    ./configure \
      --prefix=$out \
      --enable-shared --disable-static \
      CXXFLAGS="-I${gsl.dev}/include -DNONCBLAS -DNO_STRASSEN -DFORTRAN_" \
      LDFLAGS="-L${blas}/lib -L${lapack}/lib" \
      BLASLIB="-lblas" \
      CLAPACKOPT="-DNONCLAPACK" \
      CBLASOPT="-DNONCBLAS"
    make -j$NIX_BUILD_CORES
    make install
    popd

    # Build cioverlap programs (autotools C++ programs)
    pushd src/cioverlap
    autoreconf --install
    ./configure \
      --prefix=$out \
      CXXFLAGS="-I$out/include -I${gsl.dev}/include" \
      LDFLAGS="-L$out/lib -L${blas}/lib -L${lapack}/lib -L${gsl}/lib -L${lib.getLib gfortran.cc}/lib" \
      LIBS="-lblas -llapack -lgsl -lgslcblas -lla -lgfortran"
    make -j$NIX_BUILD_CORES
    popd

    # Build cioverlap-od (Fortran, simple Makefile)
    pushd src/cioverlap-od
    make all \
      FCMPLR=gfortran \
      FFLAGS="-fbacktrace -O3 -frecursive" \
      LDFLAGS="-L${lapack}/lib -L${blas}/lib" \
      LDLIBS="-llapack -lblas"
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Install cioverlap programs
    for prog in civecconsolidate civeccompare matrix2bin bin2smatrix bin2matrix bin4index readsifs cioverlap cis_slatergen cis_casida; do
      [ -f "src/cioverlap/$prog" ] && cp "src/cioverlap/$prog" $out/bin/
    done

    # Install cioverlap-od
    cp src/cioverlap-od/EXE_ciood/cioverlap $out/bin/cioverlap.od

    chmod +x $out/bin/*

    runHook postInstall
  '';

  meta = with lib; {
    description = "CI vector overlap calculation tools for non-adiabatic molecular dynamics";
    homepage = "https://gitlab.com/light-and-molecules/cioverlap";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
})
