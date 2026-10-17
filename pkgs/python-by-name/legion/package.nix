{ buildPythonPackage
, lib
, newtonxSrc
, setuptools
, numpy
, scipy
, h5py
, gfortran
, meson
, ninja
, pkg-config
}:

buildPythonPackage (finalAttrs: {
  pname = "legion";
  version = "1.0.0";
  pyproject = true;

  src = newtonxSrc;

  sourceRoot = "source/Legion";

  build-system = [ setuptools ];

  nativeBuildInputs = [
    gfortran
    meson
    ninja
    pkg-config
  ];

  dependencies = [
    numpy
    scipy
    h5py
  ];

  # setup.py compiles Fortran modules via f2py at build time
  postPatch = ''
    # Ensure version string is PEP 440 compliant
    sed -i 's/__version__ = .*/__version__ = "1.0.0"/' src/__version__.py 2>/dev/null || true
  '';

  pythonImportsCheck = [ "legion" ];

  meta = with lib; {
    description = "Nonadiabatic molecular dynamics with Gaussian wavepackets (Newton-X package component)";
    homepage = "https://gitlab.com/light-and-molecules/legion";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
})
