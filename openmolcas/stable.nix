{ openmolcas, fetchFromGitHub, fetchpatch, mpi, globalarrays, hdf5-full, gfortran, chemps2 } :

#
# Override the upstream derivation
#

let
  srcLibwfa = fetchFromGitHub {
    owner = "libwfa";
    repo = "libwfa";
    rev = "efd3d5bafd403f945e3ea5bee17d43e150ef78b2";
    sha256 = "0qzs8s0pjrda7icws3f1a55rklfw7b94468ym5zsgp86ikjf2rlz";
  };

in (openmolcas.override {
  openmpi = mpi;
  globalarrays = globalarrays;
  hdf5-cpp = hdf5-full;
}).overrideAttrs (x: {
  cmakeFlags = x.cmakeFlags ++ [ "-DWFA=ON" "-DCHEMPS2=ON" "-DCHEMPS2_DIR=${chemps2}/bin"];

  buildInputs = x.buildInputs ++ [ chemps2 ];

  patches = [ (fetchpatch {
    name = "excessive-h5-size"; # Can be removed in the update
    url = "https://gitlab.com/Molcas/OpenMolcas/commit/73fae685ed8a0c41d5109ce96ade31d4924c3d9a.patch";
    sha256 = "1wdk1vpc0y455dinbxhc8qz3fh165wpdcrhbxia3g2ppmmpi11sc";
  }) ];

  prePatch = ''
    rm -r External/libwfa
    cp -r ${srcLibwfa} External/libwfa
    chmod -R u+w External/
  '';

  doInstallCheck = true;

  installCheckPhase = ''
     #
     # Minimal check if installation runs properly
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

     echo "Check for sucessful run:"
     grep "Happy landing" $inp.status
     echo "Check for correct energy:"
     grep "Total SCF energy" $inp.out | grep 74.880174
  '';
})
