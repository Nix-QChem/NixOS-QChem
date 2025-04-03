{ stdenv
, lib
, fetchFromGitLab
, gfortran
, unzip
, xorg
, libGL
, motif
, mkl
, flint
}:

stdenv.mkDerivation rec {
  pname = "multiwfn";
  version = "3.8-2025-03-31";

  src = fetchFromGitLab {
    owner = "theoretical-chemistry-jena/quantum-chemistry";
    repo = pname;
    rev = "736fcdd2b2342df78c6c2c910e2e2643683991e9";
    hash = "sha256-o3mAG+0YVXdmSkpETzvM1tWY97b+GDk4MM2jCJKlyUE=";
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
