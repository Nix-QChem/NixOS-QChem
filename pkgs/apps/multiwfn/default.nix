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
  version = "3.8-2023-07-19";

  src = fetchFromGitLab {
    owner = "theoretical-chemistry-jena/quantum-chemistry";
    repo = pname;
    rev = "ee06ab8a3d9d1f04644d5f1f7c67401a6a976a09";
    hash = "sha256-IsH+lQHhlMDpw6Qydz/uyiqY5Io/r3Mi69OD0YNjWfY=";
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
