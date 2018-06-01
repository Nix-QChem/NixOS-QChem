{ stdenv, fetchurl, cmake, gfortran, perl
, openblas, hdf5-cpp, python3, texLive
, makeWrapper
} :

let
  version = "master-o180529-0800";
  python = python3.withPackages (ps : with ps; [ six pyparsing ]);

in stdenv.mkDerivation {
  name = "openmolcas-${version}";

  src = fetchurl {
    url = "https://gitlab.com/Molcas/OpenMolcas/repository/${version}/archive.tar.bz2";
    sha256 = "0dr5i7b2mklnrcy6y6q9snahbxv2l7s38090my553g5kl5xb3r8x";
  };

  nativeBuildInputs = [ perl cmake texLive makeWrapper ];
  buildInputs = [ gfortran openblas hdf5-cpp python ];

  cmakeFlags = [
    "-DOPENMP=ON"
    "-DLINALG=OpenBLAS"
    "-DTOOLS=OFF"
    "-DHDF5=ON"
    "-DCTEST=ON"
    "-DOPENBLASROOT=${openblas}"
  ];

  postConfigure = ''
    mkdir -p $out/bin
    export PATH=$PATH:$out/bin

    echo ${python}
  '';

  postFixup = ''
    # Wrong store path in shebang (no Python pkgs), force re-patching
    sed -i "1s:/.*:/usr/bin/env python:" $out/bin/pymolcas
    patchShebangs $out/bin

    wrapProgram $out/bin/pymolcas --set MOLCAS $out
  '';

  installCheckPhase = ''
     #
     # Minimal check if installation is runs
     #

     export MOLCAS_WORKDIR=./
     inp=water

     cat << EOF > $inp.xyz
     3
     Angstrom
     O       0.000000  0.000000  0.000000
     H       0.758602  0.000000  0.504284
     H       0.758602  0.000000 -0.504284
     EOF

     cat << EOF > $inp.inp
     &GATEWAY
     coord=water.xyz
     basis=sto-3g
     &SEWARD
     &SCF
     EOF

     $out/bin/pymolcas $inp.inp > $inp.out

     grep "Happy landing" $inp.status

     grep "Total SCF energy"  $inp.out | grep 74.880174
  '';

  doInstallCheck = true;

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Quantum chemistry software package";
    homepage = https://gitlab.com/Molcas/OpenMolcas;
    license = with licenses; lgpl21;
    platforms = with platforms; linux;
  };
}

