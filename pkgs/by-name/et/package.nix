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
stdenv.mkDerivation rec {
  pname = "et";
  version = "20250319";

  src = fetchFromGitLab {
    owner = "eT-program";
    repo = "eT";
    rev = "ae16f1f8417dbfb6af9ee2a025f7c58a87972b0d";
    hash = "sha256-7gQwtlLSOxiy3XLMwaHvWLIEVq3gw5vSiDoV1k1wz+w=";
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
    cp ../tests/hf_energy_sto3g/hf_energy_sto3g.inp .
    $out/bin/eT_launch.py --omp 2 hf_energy_sto3g.inp
    grep "Total energy:[[:space:]]*-175.0207173" hf_energy_sto3g.out

    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Electronic structure program for coupled cluster";
    homepage = "https://gitlab.com/eT-program/eT";
    maintainers = [ maintainers.markuskowa ];
    license = licenses.gpl3Only;
  };
}
