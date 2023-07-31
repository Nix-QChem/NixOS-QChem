{ buildPythonApplication
, python3
, fetchFromGitLab
, lib
, numpy
, h5py
, pyqt5
, qtpy
, future
, vtk
, qt5
}:

buildPythonApplication rec {
  pname = "Pegamoid";
  version = "2.8";

  src = fetchFromGitLab {
    owner = "jellby";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-RhUPXQvNmuDiNgS60PttvwIjpGSM1+5CaBwrrTI7XfM=";
  };


  # The samples and screenshots directories confuse setuptools and they
  # refuse to build as long as these directories are present.
  prePatch = "rm -rf samples screenshots";

  preConfigure = ''
    export PYTHONPATH=$PYTHONPATH:${vtk}/${python3.sitePackages}
  '';

  propagatedBuildInputs = [
    numpy
    h5py
    pyqt5
    qtpy
    vtk
    future
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
  };
}
