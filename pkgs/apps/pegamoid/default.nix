{ buildPythonApplication
, python
, setuptools
, fetchFromGitLab
, lib
, numpy
, h5py
, pyqt5
, qtpy
, vtk
, qt5
}:

buildPythonApplication rec {
  pname = "Pegamoid";
  version = "2.12.3";

  src = fetchFromGitLab {
    owner = "jellby";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-QEEF3KZp0u5uRzYk4B7VVbV7nCbGhovlZxljQLn3g48=";
  };


  # The samples and screenshots directories confuse setuptools and they
  # refuse to build as long as these directories are present.
  prePatch = "rm -rf samples screenshots";

  pyproject = true;
  build-system = [ setuptools ];

  preConfigure = ''
    export PYTHONPATH=$PYTHONPATH:${vtk}/${python.sitePackages}
  '';

  propagatedBuildInputs = [
    numpy
    h5py
    pyqt5
    qtpy
    vtk
  ];

  nativeBuildInputs = [ qt5.wrapQtAppsHook ];

  preFixup = ''
    wrapQtApp "$out/bin/pegamoid.py"
  '';

  meta = with lib; {
    description = "Python GUI for OpenMolcas";
    homepage = "https://pypi.org/project/Pegamoid";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "pegamoid.py";
    broken = true; # https://gitlab.com/Jellby/Pegamoid/-/issues/23
  };
}
