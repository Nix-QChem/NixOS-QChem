{ lib
, stdenv
, fetchFromGitHub
, boost
, hdf5
, eigen
, blas
, lapack
, mpi
}:


stdenv.mkDerivation {
  pname = "dice";
  version = "1.0-unstable-2025-06-15";

  src = fetchFromGitHub {
    owner = "sanshar";
    repo = "dice";
    rev = "f0f0850de73f2f02953ff6552315889d47255b6f";
    hash = "sha256-LK0FOcvneHsKxogX7yu1p2yOzM18F95jjYBRqrYCcEc=";
  };

  buildInputs = [
    boost
    eigen
    hdf5
    blas
    lapack
  ];

  propagatedBuildInputs = [ mpi ];
  propagatedUserEnvPkgs = [ mpi ];

  makeFlags = [
    "USE_MPI=yes"
    "USE_INTEL=no"
    "EIGEN=${lib.getDev eigen}/include/eigen3"
    "BOOST_ROOT=${boost}"
    "HDF5=${hdf5}"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/dice}
    cp -r bin lib $out/.
    cp -r examples $out/share/dice

    runHook postInstall
  '';

  # Some example files are broken symlinks. They are not problematic for runtime
  # behaviour.
  dontCheckForBrokenSymlinks = true;

  passthru = { inherit mpi; };

  meta = with lib; {
    description = "Heatbath configuration interaction program";
    homepage = "https://github.com/sanshar/Dice";
    license = licenses.gpl3Only;
    maintainers = [ maintainers.sheepforce ];
    platforms = [ "x86_64-linux" ];
  };
}
