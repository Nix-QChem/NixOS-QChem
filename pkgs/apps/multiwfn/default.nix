{ stdenv, lib, makeWrapper, gfortran, unzip, fetchurl, xorg, libGL, motif, mkl
, arb, flint }:

stdenv.mkDerivation rec {
  pname = "multiwfn";
  version = "3.8-2022-11-14";

  src = fetchurl {
    url = "http://sobereva.com/multiwfn/misc/Multiwfn_3.8_dev_src_Linux.zip";
    hash = "sha256-5nncT+qj8vGRLVsXh8DIFBPYs3U3CwFedaqP0u3C/kU=";
  };

  patches = [
    ./gfortran.patch
    ./cp2k.patch
  ];

  nativeBuildInputs = [
    gfortran
    makeWrapper
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
