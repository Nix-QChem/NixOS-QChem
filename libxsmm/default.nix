{ stdenv, fetchFromGitHub, which
, gfortran, python, blas, utillinux
} :

let
  version = "1.10";

in stdenv.mkDerivation rec {
  name = "libxsmm-${version}";

  src = fetchFromGitHub {
    owner = "hfp";
    repo = "libxsmm";
    rev = version;
    sha256 = "13rika8f2f975nsgf5si7xippwfd5g0rbxirv3q15nrmhc079iq4";
  };

  nativeBuildInputs = [ which python utillinux ];
  buildInputs = [ gfortran ];

  postPatch = ''
    patchShebangs ./scripts
    patchShebangs ./tests
    patchShebangs .mktmp.sh
  '';

  makeFlags = [
    "STATIC=0"
    "FC=gfortran"
    "AVX=2"
  ];

  preInstall = ''
    mkdir -p $out
    installFlagsArray+=("PREFIX=$out")
  '';

  enableParallelBuilding = true;

  checkInputs = [ blas ];

  doCheck = false;

  meta = with stdenv.lib; {
    description = "Library for specialized dense and sparse matrix operations targeting Intel Architecture";
    homepage = https://github.com/hfp/libxsmm;
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    platforms = [ "x86_64-linux" ] ;
  };
}

