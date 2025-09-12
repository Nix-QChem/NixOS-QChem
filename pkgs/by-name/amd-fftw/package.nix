{ fetchFromGitHub
, stdenv
, lib
, gfortran
, perl
, llvmPackages ? null
, precision ? "double"
, enableAvx ? true
, enableAvx2 ? true
, amdArch ? "znver2"
, enableMpi ? false
, mpi
}:

stdenv.mkDerivation rec {
  pname = "amd-fftw";
  version = "5.1";

  src = fetchFromGitHub {
    owner = "amd";
    repo = "amd-fftw";
    rev = version;
    hash = "sha256-U0YoAdE2cOIgKtfq5K3+1aCxOO0k9ZayMnrp7za2Auo=";
  };

  patches = [
    # remove mtune=native impurity
    ./mtune.patch
  ];

  outputs = [ "out" "dev" "man" "info" ];
  outputBin = "dev"; # fftw-wisdom

  nativeBuildInputs = [ gfortran ];

  buildInputs = lib.optionals stdenv.cc.isClang [
    # TODO: This may mismatch the LLVM version sin the stdenv, see #79818.
    llvmPackages.openmp
  ] ++ lib.optional enableMpi mpi;

  AMD_ARCH = amdArch;

  configureFlags = # --enable-fma and --enable-avx-128-fma flags are broken
    [ "--enable-shared"
      "--enable-threads"
      "--enable-amd-opt"
    ]
    ++ lib.optional (precision != "double") "--enable-${precision}"
    # all x86_64 have sse2
    # however, not all float sizes fit
    ++ lib.optional (stdenv.isx86_64 && (precision == "single" || precision == "double") )  "--enable-sse2"
    ++ lib.optional enableAvx "--enable-avx"
    ++ lib.optional enableAvx2 "--enable-avx2"
    ++ lib.optionals enableMpi [ "--enable-mpi" "--enable-amd-trans" "--enable-amd-mpifft" ]
    ++ [ "--enable-openmp" ];

  enableParallelBuilding = true;

  checkInputs = [ perl ];

  meta = with lib; {
    description = "Fastest Fourier Transform in the West library optimized for AMD Epyc CPUs";
    homepage = "http://www.fftw.org/";
    license = licenses.gpl2Plus;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}

