{ stdenv
, lib
, fetchFromGitHub
, cmake
, catch2_3
}:

stdenv.mkDerivation rec {
  pname = "IntegratorXX";
  version = "unstable-2023-08-10";

  src = fetchFromGitHub {
    owner = "wavefunction91";
    repo = pname;
    rev = "ea07dedd37e7bd49ea06394eb811599002b34b49";
    hash = "sha256-L9IuzkvQGxfUJ+7x63IxETfvIwCCcxWW9AXUKTnKMYY=";
  };

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = with lib.strings; [
    (cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
  ];

  checkInputs = [ catch2_3 ];

  doCheck = true;

  meta = with lib; {
    description = "Reusable DFT Grids for the Masses";
    homepage = "https://github.com/wavefunction91/IntegratorXX";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.sheepforce ];
  };
}
