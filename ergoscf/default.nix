{ stdenv, fetchurl, openblas } :

let
  version = "3.7";

in stdenv.mkDerivation {
  name = "ergoscf-${version}";

  src = fetchurl {
    url = http://www.ergoscf.org/source/tarfiles/ergo-3.7.tar.gz;
    sha256 = "1vmw8bw996zlds4j5yg08889xngbdpa51l6gilcjsr130sb0dhvv";
  };

  nativeBuildInputs = [ ];
  buildInputs = [ openblas ];

  patches = [ ./math-constants.patch ];

  postPatch = ''
    patchShebangs ./test
  '';

  configureFlags = [
    "--enable-sse-intrinsics"
    "--enable-linalgebra-templates"
    "--enable-performance"
  ];

  LDFLAGS = "-lopenblas";
  CXXFLAGS = "-fopenmp";

  enableParallelBuilding = true;

  OMP_NUM_THREADS = 2; # required for check phase

  doCheck = true;

  meta = with stdenv.lib; {
    description = "Quantum chemistry program for large-scale self-consistent field calculations";
    homepage = http://http://www.ergoscf.org;
    license = licenses.gpl3;
    maintainers = [ maintainers.markuskowa ];
    platforms = platforms.linux;
  };
}

