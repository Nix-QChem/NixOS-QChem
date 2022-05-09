{ buildPythonApplication, fetchFromGitLab, lib
, numpy, h5py, pyqt5, qtpy, future, vtk
} :

buildPythonApplication rec {
  pname = "Pegamoid";
  version = "2.6.2";

  src = fetchFromGitLab {
    owner = "jellby";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-36ZZK2cACvrwn5EVuv+zu6oBsh3vPCZDxQGzKe4PPlg=";
  };


  # The samples and screenshots directories confuse setuptools and they
  # refuse to build as long as these directories are present.
  prePatch = "rm -rf samples screenshots";
  patches = [ ./pipVTK.patch ];

  propagatedBuildInputs = [
    numpy
    h5py
    pyqt5
    qtpy
    vtk
    future
  ];

  meta = with lib; {
    description = "Python GUI for OpenMolcas";
    homepage = "https://pypi.org/project/Pegamoid";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    mainProgram = "pegamoid.py";
  };
}
