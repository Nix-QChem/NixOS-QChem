{ stdenv
, lib
, newtonxSrc
, gfortran
, meson
, ninja
, pkg-config
, git
, python3
, blas
, lapack
, hdf5-full
}:

let
  pythonEnv = python3.withPackages (p: with p; [
    h5py
    numpy
    matplotlib
    pandas
  ]);

in
stdenv.mkDerivation (finalAttrs: {
  pname = "newtonx-ns";
  version = "26a";

  src = newtonxSrc;

  sourceRoot = "source/NX-NS";

  nativeBuildInputs = [
    gfortran
    meson
    ninja
    pkg-config
    git
    pythonEnv
  ];

  buildInputs = [
    blas
    lapack
    hdf5-full
  ];

  propagatedBuildInputs = [
    pythonEnv
  ];

  mesonFlags = [
    "-Dlapack=netlib"
    "-Dhdf5=true"
  ];

  postPatch = ''
    # gfortran 16: pure functions cannot have polymorphic allocatable
    # components in their result. Use impure instead.
    substituteInPlace $(find src -name '*.f90') \
      --replace "pure function constructor" "impure function constructor"
  '';

  postInstall = ''
    # Install auxiliary scripts that are symlinked in the release bin/
    install -Dm755 ${newtonxSrc}/NX-NS/scripts/dat2hdf5.py $out/bin/dat2hdf5.py
    install -Dm755 ${newtonxSrc}/NX-NS/scripts/get_last_times.sh $out/bin/get_last_times.sh
    install -Dm755 ${newtonxSrc}/NX-NS/scripts/nx_gen_dataset.py $out/bin/nx_gen_dataset.py
    install -Dm755 ${newtonxSrc}/NX-NS/scripts/plot_pop.py $out/bin/plot_pop.py
    patchShebangs $out/bin
  '';

  meta = with lib; {
    description = "Newton-X NS: surface hopping molecular dynamics (core Fortran code)";
    homepage = "https://gitlab.com/light-and-molecules/newtonx";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "nx_moldyn";
  };
})
