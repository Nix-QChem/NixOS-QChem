{ stdenv
, lib
, fetchurl
, gfortran
, cmake
, fftw
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "tinker";
  version = "8.10.5";

  src = fetchurl {
    url = "https://dasher.wustl.edu/tinker/downloads/tinker-${version}.tar.gz";
    hash = "sha256-RnN4Px2PNpyekK3W+L5K64ppaVJf2MCbb5e3ypMpTpQ=";
  };

  preConfigure = ''
    cd source
    cp ../cmake/CMakeLists.txt .
  '';

  nativeBuildInputs = [
    cmake
    gfortran
    pkg-config
  ];

  buildInputs = [ fftw ];

  postInstall = ''
    mkdir -p $out/share/tinker
    cp -r ../../params $out/share/tinker

    for exe in $(find $out/bin/ -type f -executable -name "*.x"); do
      ln -s $exe $out/bin/$(basename $exe .x)
    done
  '';

  meta = with lib; {
    description = "Software Tools for Molecular Design";
    homepage = "https://github.com/TinkerTools/tinker";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
