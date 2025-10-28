{ stdenv
, lib
, fetchFromGitHub
, cmake
, catch2_3
}:

stdenv.mkDerivation rec {
  pname = "IntegratorXX";
  version = "unstable-2025-09-09";

  src = fetchFromGitHub {
    owner = "wavefunction91";
    repo = pname;
    rev = "1369be58d7a3235dac36d75dd964fef058830622";
    hash = "sha256-+ZThFqJ9Z1aTpwoVIbnAZ7VkFVdHxpjpnylYVxtB6jA=";
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
