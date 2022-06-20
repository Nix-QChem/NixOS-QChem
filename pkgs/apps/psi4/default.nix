{ lib, stdenv, buildPythonPackage, buildPackages, makeWrapper, fetchFromGitHub, fetchurl, pkg-config
, writeTextFile, cmake, ninja, perl, gfortran, python, pybind11, qcelemental, qcengine, numpy, pylibefp
, deepdiff, blas, lapack, gau2grid, libxc, dkh, dftd3, pcmsolver, libefp, libecpint, cppe
, chemps2, hdf5, hdf5-cpp, pytest, mpfr, gmpxx, eigen, boost, adcc
} :

let
  # Psi4 requires some special cmake flags. Using Nix's defaults usually does not work.
  specialInstallCmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=$out"
    "-DNAMESPACE_INSTALL_INCLUDEDIR=/"
    "-DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF"
    "-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF"
    "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON"
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
  ];

  chemps2_ = chemps2.overrideAttrs (oldAttrs: rec {
    configurePhase = ''
      cmake -Bbuild ${toString specialInstallCmakeFlags}
      cd build
    '';
  });

  dkh_ = dkh.overrideAttrs (oldAttrs: rec {
    enableParallelBuilding = true;
    configurePhase = "cmake -Bbuild ${toString (oldAttrs.cmakeFlags ++ specialInstallCmakeFlags)}";
    preBuild = "cd build";
  });

  pcmsolver_ = pcmsolver.overrideAttrs (oldAttrs: rec {
    enableParallelBuilding = true;
    configurePhase = ''
      cmake -Bbuild ${toString (oldAttrs.cmakeFlags ++ specialInstallCmakeFlags)}
      cd build
    '';
  });

  /* This is libint built with high maximum angular momentum. The code generator
     first runs to generate libint itself and then builds. Will take forever ...
  libint = stdenv.mkDerivation rec {
    pname = "libint";
    version = "2.7.1";

    # This is the current state of loriab/libint/new-cmake-harness-lab-rb1 at Psi4 1.6 release
    src = fetchurl {
      url = "https://github.com/loriab/${pname}/archive/9f12ee61e1ce52420fe3020712c3584cb3e9a1b4.tar.gz";
      hash = "sha256-xlsVLCjBlP3Xf7qrTqZO9Y8Oo7eIieRKBz2jxphSGM0=";
    };

    nativeBuildInputs = [ cmake ninja ];
    propagatedBuildInputs = [ eigen boost mpfr ];

    preConfigure = ''
      ulimit -s 65536
      cmakeFlagsArray+=(
        ${builtins.toString specialInstallCmakeFlags}
        -GNinja
        -DCMAKE_BUILD_TYPE=Release
        -DENABLE_ONEBODY=2
        -DENABLE_ERI=2
        -DENABLE_ERI3=2
        -DENABLE_ERI2=2
        -DERI3_PURE_SH=OFF
        -DERI2_PURE_SH=OFF
        -DLIBINT2_SHGAUSS_ORDERING=gaussian
        -DLIBINT2_CARTGAUSS_ORDERING=standard
        -DLIBINT2_SHELL_SET=standard
        -DBUILD_SHARED_LIBS=ON
        -DLIBINT2_BUILD_SHARED_AND_STATIC_LIBS=ON
        -DREQUIRE_CXX_API=ON
        -DREQUIRE_CXX_API_COMPILED=OFF
        -DENABLE_FORTRAN=OFF
        -DENABLE_XHOST=ON
        -DBUILD_FPIC=ON
        -DWITH_MAX_AM=7
        #-DCMAKECONFIG_INSTALL_DIR=$out/share/cmake/Libint2
      )
    '';
  };
  */

  libint = stdenv.mkDerivation rec {
    pname = "libint";
    version = "2.7.1";

    src = fetchurl {
      url = "https://github.com/loriab/libint/releases/download/v0.1/Libint2-export-5-4-3-6-5-4_mm4f12ob2.tgz";
      hash = "sha256-Lh5FYJkhhawPvHTFO8gEdhFe+dCvYMmtZMUQ6+YjVYQ=";
    };

    nativeBuildInputs = [ cmake ninja ];
    propagatedBuildInputs = [ eigen boost mpfr ];

    preConfigure = ''
      ulimit -s 65536
      cmakeFlagsArray+=(
        ${builtins.toString specialInstallCmakeFlags}
        -GNinja
        -DCMAKE_BUILD_TYPE=Release
        -DENABLE_ONEBODY=2
        -DENABLE_ERI=2
        -DENABLE_ERI3=2
        -DENABLE_ERI2=2
        -DERI3_PURE_SH=OFF
        -DERI2_PURE_SH=OFF
        -DLIBINT2_SHGAUSS_ORDERING=gaussian
        -DBUILD_SHARED_LIBS=ON
        -DLIBINT2_BUILD_SHARED_AND_STATIC_LIBS=ON
        -DREQUIRE_CXX_API=ON
        -DREQUIRE_CXX_API_COMPILED=OFF
        -DBUILD_FPIC=ON
      )
    '';
  };

  testInputs = {
    h2o_omp25_opt = writeTextFile {
      name = "h2o_omp25_opt";
      text = ''
        memory 1 GB
        molecule Water {
        0 1
        O
        H 1 0.8
        H 1 0.8 2 110
        }

        set {
        basis cc-pvdz
        scf_type df
        mp_type df
        reference rhf
        }

        optimize("omp2.5")
      '';
    };
  };

in buildPythonPackage rec {
    pname = "psi4";
    version = "1.6";

    nativeBuildInputs = [
      cmake
      perl
      gfortran
      makeWrapper
      pkg-config
      pytest
    ];

    buildInputs = [
      gau2grid
      libxc
      blas
      lapack
      dkh_
      pcmsolver_
      libefp
      libecpint
      cppe
      chemps2_
      hdf5
      hdf5-cpp
      gmpxx
      libint
    ];

    propagatedBuildInputs = [
      adcc
      pybind11
      qcelemental
      qcengine
      numpy
      pylibefp
      deepdiff
      dftd3
      chemps2_
    ] ++ qcelemental.passthru.requiredPythonModules
      ++ qcengine.passthru.requiredPythonModules
    ;

    checkInputs = [
      pytest
    ];

    src = fetchFromGitHub {
      repo = pname;
      owner = "psi4";
      rev = "v${version}";
      sha256 = "sha256-x+Nqpxe3TBx9NUET0MdfwwE/YQ+B7BirIlYXXFhNopI=";
    };

    cmakeFlags = [
      "-DDCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF"
      "-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF"
      "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON"
      "-DCMAKE_INSTALL_PREFIX=$out"
      "-DBUILD_SHARED_LIBS=ON"
      "-DENABLE_XHOST=OFF"
      "-DENABLE_OPENMP=ON"
      # gau2grid
      "-DCMAKE_INSIST_FIND_PACKAGE_gau2grid=ON"
      "-Dgau2grid_DIR=${gau2grid}/share/cmake/gau2grid"
      # libint
      "-DMAX_AM_ERI=5"
      "-DBUILD_SHARED_LIBS=ON"
      "-DCMAKE_INSIST_FIND_PACKAGE_Libint=ON"
      "-DLibint2_DIR=${libint}/share/cmake/Libint2"
      # libxc
      "-DCMAKE_INSIST_FIND_PACKAGE_Libxc=ON"
      "-DLibxc_DIR=${libxc}/share/cmake/Libxc"
      # pcmsolver
      "-DCMAKE_INSIST_FIND_PACKAGE_PCMSolver=ON"
      "-DENABLE_PCMSolver=ON"
      "-DPCMSolver_DIR=${pcmsolver_}/share/cmake/PCMSolver"
      # DKH
      "-DENABLE_dkh=ON"
      "-DCMAKE_INSIST_FIND_PACKAGE_dkh=ON"
      "-Ddkh_DIR=${dkh_}/share/cmake/dkh"
      # CPPE
      "-DENABLE_cppe=ON"
      "-Dcppe_DIR=${cppe}"
      # LibEcpInt
      "-DENABLE_ecpint=ON"
      "-Decpint_DIR=${libecpint}"
      # LibEFP
      "-DENABLE_libefp=ON"
      # CheMPS2
      "-DENABLE_CheMPS2=ON"
      # Prefix path for all external packages
      "-DCMAKE_PREFIX_PATH=\"${gau2grid};${libxc};${qcelemental};${pcmsolver_};${dkh_};${libefp};${chemps2_};${libint};${libecpint};${cppe}\""
      # ADCC
      "-DENABLE_adcc=ON"
    ];

    format = "other";
    enableParallelBuilding = true;

    configurePhase = ''
      runHook preConfigure

      cmake -Bbuild ${toString cmakeFlags} -DCMAKE_INSTALL_PREFIX=$out
      cd build

      runHook postConfigure
    '';

    postFixup = let
      binSearchPath = with lib; strings.makeSearchPath "bin" [ dftd3 ];

    in ''
      # Make libraries and external binaries available
      wrapProgram $out/bin/psi4 \
        --prefix PATH : ${binSearchPath}

      # Symlinks so that the lib directory is easy to find for python.
      mkdir -p $out/lib/${python.executable}/site-packages
      ln -s $out/lib/psi4 $out/lib/${python.executable}/site-packages/.

      # The symlink needs a fix for the PSIDATADIR on python side as its expecting to be installed
      # somewhere else.
      substituteInPlace $out/lib/${python.executable}/site-packages/psi4/__init__.py \
        --replace 'elif "CMAKE_INSTALL_DATADIR" in data_dir:' 'else:' \
        --replace 'data_dir = os.path.sep.join([os.path.abspath(os.path.dirname(__file__)), "share", "psi4"])' 'data_dir = "@out@/share/psi4"' \
        --subst-var out
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      export OMP_NUM_THREADS=2
      $out/bin/psi4 -i ${testInputs.h2o_omp25_opt} -o out1.out -n 2 && grep "Final energy is    -76.235085" out1.out
    '';

    meta = with lib; {
      description = "Open-Source Quantum Chemistry – an electronic structure package in C++ driven by Python";
      homepage = "http://www.psicode.org/";
      license = licenses.lgpl3;
      platforms = platforms.linux;
      maintainers = [ maintainers.sheepforce ];
    };
  }
