{ stdenv
, lib
, fetchFromGitLab
, gfortran
, unzip
, xorg
, libGL
, motif
, mkl
, flint3
}:

stdenv.mkDerivation rec {
  pname = "multiwfn";
  version = "3.8-2025-10-02";

  src = fetchFromGitLab {
    owner = "theoretical-chemistry-jena/quantum-chemistry";
    repo = pname;
    rev = "6918986d31395bbcf0b62f97d2444a5dbc2a2e41";
    hash = "sha256-LSv0CbTnvT6rqzJGRx0vMeXGO0usnee+fh9g27+6n1U=";
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
    flint3
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
