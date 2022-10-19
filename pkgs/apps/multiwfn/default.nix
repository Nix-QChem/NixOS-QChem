{ stdenv, lib, makeWrapper, gfortran, unzip, fetchurl, xorg, libGL, motif, mkl }:

stdenv.mkDerivation rec {
  pname = "multiwfn";
  version = "3.8-2022-10-05";

  src = fetchurl {
    url = "http://sobereva.com/multiwfn/misc/Multiwfn_3.8_dev_src_Linux.zip";
    hash = "sha256-ON96OD61RNFPuTxs0pwF1/jlVC2l45OIdTmxsPx9cKM=";
  };

  patches = [
    ./gfortran.patch
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
  ];

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
