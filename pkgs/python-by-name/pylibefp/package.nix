{ buildPythonPackage
, lib
, fetchFromGitHub
, cmake
, fetchpatch
, pythonAtLeast
# Dependencies
, libefp
, blas
# Python
, python
, pybind11
, qcelemental
} :

buildPythonPackage rec {
  pname = "pylibefp";
  version = "0.6.2";

  src = fetchFromGitHub  {
    owner = "loriab";
    repo = pname;
    rev = "v${version}"; # v0.6.2 with CMake tweaks
    hash = "sha256-ZbNmMn5Z9MBLDcTacYKrl4Dno3Gtv2f9xvQ0Obh1s0A=";
  };

  patches = [
    (fetchpatch {
      name = "cmake4-1";
      url = "https://github.com/loriab/pylibefp/commit/ece077b65558033c2ef08ad04159b333d5767619.patch";
      hash = "sha256-QUJqDlH6PojRrRn89ppHgsRkB0vNmNCheTBz/SayHoU=";
    })
  ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    blas
    libefp
  ];

  propagatedBuildInputs = [
    python
    pybind11
    qcelemental
  ];

  format = "other";

  cmakeFlags = [
    "-DCMAKE_PREFIX_PATH=${libefp}"
    "-Dlibefp_DIR=${libefp}/share/cmake/libefp"
  ];

  meta = with lib; {
    description = "Periodic table, physical constants, and molecule parsing for quantum chemistry.";
    homepage = "http://docs.qcarchive.molssi.org/projects/qcelemental/en/latest/";
    license = licenses.bsd3;
    platforms = platforms.unix;
    broken = pythonAtLeast "3.12";
  };
}
