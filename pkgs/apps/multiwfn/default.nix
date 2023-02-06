{ stdenv
, lib
, fetchFromGitLab
, gfortran
, unzip
, xorg
, libGL
, motif
, mkl
, arb
, flint
}:

stdenv.mkDerivation rec {
  pname = "multiwfn";
  version = "3.8-2023-02-06";

  src = fetchFromGitLab {
    owner = "theoretical-chemistry-jena/quantum-chemistry";
    repo = pname;
    rev = "e5ce5e98acf0625d653901828c8e6210a85fde22";
    hash = "sha256-Ki4r0qVLoJv1jxndCi8YIwt4w/wBOAjO+0n+g6PrRSM=";
  };

  preConfigure = "cd src";

  nativeBuildInputs = [
    gfortran
    unzip
  ];

  buildInputs = [
    xorg.libX11
    xorg.libXt
    libGL
    motif
    mkl
    arb
    flint
  ];

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/multiwfn
    chmod +x Multiwfn Multiwfn_noGUI
    cp Multiwfn Multiwfn_noGUI $out/bin/.
  '';

  meta = with lib; {
    description = "Multifunctional wave function analyser.";
    license = licenses.bsd3;
    homepage = "http://sobereva.com/multiwfn/index.html";
    mainProgram = "Multiwfn";
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
