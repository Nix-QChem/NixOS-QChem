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
, swig
, enableCuda ? cfg.useCuda
, cudaPackages
}:

buildPythonPackage rec {
  pname = "vmd-python";
  version = "3.1.7";

  src = fetchFromGitHub {
    owner = "Eigenstate";
    repo = pname;
    rev = "65f10e87983d0ebd8e761a2a8499df5bf654373e";
    hash = "sha256-1koMd7GU8KQjxpL5/FOCZWr/+iFTcsF/JCm++xIgvhc=";
  };

  postPatch = ''
    patchShebangs vmd/{install.sh,vmd_src/{configure,bin/*},plugins/create_static_headers.sh}

    substituteInPlace vmd/plugins/vmdtkcon/tkcon-2.3/docs/perl.txt vmd/plugins/autoimd/namdrun.tcl vmd/vmd_src/configure \
      --replace "/bin/sh" "${runtimeShell}"
  '';

  pyproject = true;
  build-system = [ setuptools swig ];

  nativeBuildInputs = [ perl ];

  buildInputs = [
    netcdf
    expat
    sqlite
    tcl
    libGLU
    mesa
  ] ++ lib.optional enableCuda cudaPackages.cudatoolkit;

  dependencies = [
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
    broken = true; # Requires Python <= 3.12 but python dependencies in nixpkgs only build with >= 3.13.
  };
}
