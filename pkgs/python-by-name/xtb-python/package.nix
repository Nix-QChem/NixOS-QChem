{ buildPythonPackage
, lib
, pythonAtLeast
, fetchFromGitHub
, cffi
, numpy
, ase
, qcelemental
, meson
, meson-python
, ninja
, cmake
, pkg-config
, xtb
}:

buildPythonPackage rec {
  pname = "xtb-python";
  version = "22.1";

  src = fetchFromGitHub {
    owner = "grimme-lab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-TTVtPVhb7FJnvu/C2yJhxOE/KzuLxe0N4HbpbkE/MTM=";
  };

  postPatch = ''
    substituteInPlace meson.build \
      --replace "get_option('python_version')," "get_option('python_version'), pure: false,"

    cat meson.build
  '';

  nativeBuildInputs = [ meson ninja pkg-config meson-python ];

  propagatedBuildInputs = [
    cffi
    numpy
    ase
    qcelemental
    xtb
  ];

  format = "pyproject";

  # Build a C module to interface XTB.
  preBuild = ''
    meson setup build --prefix=$(pwd) --default-library=shared
    ninja -C build install
  '';

  pythonImportsCheck = [ "xtb.interface" "xtb.libxtb" ];
  preCheck = "export OMP_NUM_THREADS=4";

  meta = with lib; {
    description = "Python wrapper for the semiempirical XTB package";
    homepage = "https://github.com/grimme-lab/xtb-python";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    broken = pythonAtLeast "3.12";
  };
}
