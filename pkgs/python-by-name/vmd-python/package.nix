{ buildPythonPackage
, lib
, pythonAtLeast
, setuptools
, runtimeShell
, cfg
, fetchFromGitHub
, netcdf
, expat
, sqlite
, tcl
, perl
, libGLU
, mesa
, numpy
, importlib-resources
, pytest
, enableCuda ? cfg.useCuda
, cudaPackages
}:

buildPythonPackage rec {
  pname = "vmd-python";
  version = "3.1.4";

  src = fetchFromGitHub {
    owner = "Eigenstate";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-4XZfQkLNhgdVNubjz99pg8Tet0t+bjoR/rFtsPxrZY0=";
  };

  postPatch = ''
    patchShebangs vmd/{install.sh,vmd_src/{configure,bin/*},plugins/create_static_headers.sh}

    substituteInPlace vmd/plugins/vmdtkcon/tkcon-2.3/docs/perl.txt vmd/plugins/autoimd/namdrun.tcl vmd/vmd_src/configure \
      --replace "/bin/sh" "${runtimeShell}"
  '';

  pyproject = true;
  build-system = [ setuptools ];

  nativeBuildInputs = [ perl ];

  buildInputs = [
    netcdf
    expat
    sqlite
    tcl
    libGLU
    mesa
  ] ++ lib.optional enableCuda cudaPackages.cudatoolkit;

  propagatedBuildInputs = [
    numpy
    importlib-resources
  ];

  preConfigure = ''
    export LD_LIBRARY_PATH=${lib.makeLibraryPath buildInputs}
  '';

  checkInputs = [ pytest ];

  meta = with lib; {
    description = "Installable VMD as a python module";
    homepage = "https://github.com/Eigenstate/vmd-python";
    license = licenses.unfree;
    maintainers = [ maintainers.sheepforce ];
    broken = pythonAtLeast "3.12";
  };
}
