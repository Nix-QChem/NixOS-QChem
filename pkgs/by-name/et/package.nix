{
  lib,
  stdenv,
  fetchFromGitLab,
  cmake,
  gfortran,
  python3,
  ninja,
  makeWrapper,
  boost,
  eigen,
  blas-ilp64,
  lapack-ilp64,
  libcint,
}:

let
  # Custom build with static library
  libcint' = libcint.overrideAttrs (x: {
    cmakeFlags = x.cmakeFlags ++ [
      "-DPYPZPX=1"
      "-DBUILD_SHARED_LIBS=0"
    ];
  });
in
stdenv.mkDerivation (final: {
  pname = "et";
  version = "2.0.1";

  src = fetchFromGitLab {
    owner = "eT-program";
    repo = "eT";
    tag = "v${final.version}";
    hash = "sha256-bU2rCwC6ADZMEOaBvEgIP25hhOoeYhP5W5Yh4RqLTT4=";
  };

  patches = [ ./argparse.patch ];

  nativeBuildInputs = [
    cmake
    ninja
    gfortran
    python3
    makeWrapper
  ];

  buildInputs = [
    boost
    eigen
    blas-ilp64
    lapack-ilp64
    libcint'
    python3
  ];

  LIBCINT_ROOT = "${libcint'}";

  # Distilled from setup.py which also runs cmake
  preConfigure = ''
    python3 <<EOF
    from dev_tools.autogenerate_files import autogenerate
    from pathlib import Path
    autogenerate(Path("./."))
    EOF
  '';

  # cmake files do not define an install phase
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/eT

    cp eT $out/bin
    cp eT_launch.py $out/bin
    cp -r ../ao_basis $out/share/eT

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/eT_launch.py \
      --set-default AO_BASIS_PATH "$out/share/eT/ao_basis" \
      --add-flags "-bd $out/bin"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    # Minimalistic check
    cp ../tests/hf_3-21g/hf_3-21g.inp .
    $out/bin/eT_launch.py --omp 2 hf_3-21g.inp
    grep "Total energy:[[:space:]]*-176.449193" hf_3-21g.out

    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Electronic structure program for coupled cluster";
    homepage = "https://gitlab.com/eT-program/eT";
    maintainers = [ maintainers.markuskowa ];
    license = licenses.gpl3Only;
  };
})
