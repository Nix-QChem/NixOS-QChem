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
  version = "2024-07-02";

  src = fetchFromGitHub {
    owner = "sanshar";
    repo = "dice";
    rev = "0f52b621b79cfef83dc161e0a30120f7cc86bd42";
    hash = "sha256-v33uaFY9m2Aewm48iePHUuKBMkxcdMLgin10s/PYgcc=";
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
