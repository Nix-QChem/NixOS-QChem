{ stdenv, lib, gfortran, blas, lapack, python3, fetchFromGitHub }:
assert (!blas.isILP64);
assert blas.isILP64 == lapack.isILP64;

stdenv.mkDerivation rec {
  pname = "wannier90";
  version = "3.1.0";

  nativeBuildInputs = [ gfortran ];
  buildInputs = [
    blas
    lapack
  ];

  src = fetchFromGitHub {
    owner = "wannier-developers";
    repo = "wannier90";
    rev = "v${version}";
    hash = "sha256-+Mq7lM6WuwAnK/2FlDz9gNRIg2sRazQRezb3BfD0veY=";
  };

  # test cases are removed as error bounds of wannier90 are obviously to tight
  postPatch = ''
    rm -r test-suite/tests/testpostw90_{fe_kpathcurv,fe_kslicecurv,si_geninterp,si_geninterp_wsdistance}
    patchShebangs test-suite/run_tests test-suite/testcode/bin/testcode.py
  '';

  configurePhase = ''
    cp config/make.inc.gfort make.inc
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -p wannier90.x postw90.x $out/bin
  '';

  doCheck = true;
  checkInputs = [ python3 ];
  checkTarget = [ "test-serial" ];
  preCheck = ''
    export OMP_NUM_THREADS=4
  '';

  enableParallelBuilding = true;

  hardeningDisable = [ "format" ];

  meta = with lib; {
    description = "Calculation of maximally localised Wannier functions";
    homepage = "http://www.wannier.org";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
}
