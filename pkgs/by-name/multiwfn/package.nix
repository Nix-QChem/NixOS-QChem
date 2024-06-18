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
  version = "3.8-2024-06-14";

  src = fetchFromGitLab {
    owner = "theoretical-chemistry-jena/quantum-chemistry";
    repo = pname;
    rev = "2aa317686863ef06d7abfc0a259009262e994d76";
    hash = "sha256-xwU7a9b3jcHidYxSAKyEzRgdCMyDvxxeXr7oa6F/Jj0=";
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
