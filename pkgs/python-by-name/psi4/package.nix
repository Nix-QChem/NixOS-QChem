{ lib
, stdenv
, buildPythonPackage
, buildPackages
, isPy311
, makeWrapper
, fetchFromGitHub
, fetchFromGitLab
, fetchurl
, pkg-config
, writeTextFile
, cmake
, perl
, gfortran
, python
, pybind11
, qcelemental
, qcengine
, numpy
, deepdiff
, blas
, lapack
, gau2grid
, libxc
, dkh
, dftd3
, pcmsolver
, libecpint
, cppe
, chemps2
, hdf5
, hdf5-cpp
, mpfr
, gmpxx
, eigen
, boost
, adcc
, optking
, qcmanybody
, pytest
, mrcc
, enableMrcc ? false
, cfour
, enableCfour ? false
}:

let
  # Psi4 requires some special cmake flags. Using Nix's defaults usually does not work.
  specialInstallCmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=$out"
    "-DNAMESPACE_INSTALL_INCLUDEDIR=/"
    "-DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF"
    "-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF"
    "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON"
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  chemps2_ = chemps2.overrideAttrs (oldAttrs: rec {
    configurePhase = ''
      cmake -Bbuild ${toString specialInstallCmakeFlags}
      cd build
    '';

    postFixup = ''
      substituteInPlace $out/share/cmake/CheMPS2/CheMPS2Config.cmake \
        --replace "1.14.1-2" "1.14.1"
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

  libintSrc = fetchurl {
    url = "https://github.com/loriab/libint/releases/download/v0.1/libint-2.8.1-7-7-4-12-7-5_mm10f12ob2_0.tgz";
    hash = "sha256-II44D4o0IwZDbTZB1qzAcCTCcXtuy1XJREP6Ic/BV4M=";
  };

  testInputs = {
    h2o_omp25_opt = writeTextFile {
      name = "h2o_omp25_opt";
      text = ''
        memory 1 GiB
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

    BaF2_dft_grad = writeTextFile {
      name = "BaF2_dft_grad";
      text = ''
        memory 1 GiB
        molecule BaF2 {
          F
          Ba 1 1.5
          F  2 1.5 1 90
        }

        set {
          basis def2-TZVP
          relativistic dkh
          scf_type df
        }

        gradient("b3lyp-d3bj")
      '';
    };
  };

in
buildPythonPackage rec {
  pname = "psi4";
  version = "1.10";

  nativeBuildInputs = [
    cmake
    perl
    gfortran
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    boost
    gau2grid
    libxc
    blas
    lapack
    dkh_
    pcmsolver_
    libecpint
    cppe
    chemps2_
    hdf5
    hdf5-cpp
    gmpxx
    eigen
  ];

  propagatedBuildInputs = [
    adcc
    pybind11
    qcelemental
    qcengine
    numpy
    deepdiff
    dftd3
    chemps2_
    optking
    qcmanybody
    pytest
  ]
  ++ qcelemental.passthru.requiredPythonModules
  ++ qcengine.passthru.requiredPythonModules
  ++ lib.optional enableMrcc mrcc
  ++ lib.optional enableCfour cfour
  ;

  src = fetchFromGitHub {
    repo = pname;
    owner = "psi4";
    tag = "v${version}";
    hash = "sha256-CzeyPuzWWsiULG8x0Ecn+3VR8cNW2UO1EOy9pZA/9c0=";
  };

  preConfigure = ''
    substituteInPlace ./external/upstream/libint2/CMakeLists.txt \
      --replace-fail 'https://github.com/loriab/libint/releases/download/v0.1/libint-2.8.1-''${_url_am_src}_mm10f12ob2_0.tgz' "file://${libintSrc}" \
  '';

  cmakeFlags = [
    "-DDCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF"
    "-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF"
    "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON"
    "-DCMAKE_INSTALL_PREFIX=$out"
    "-DBUILD_SHARED_LIBS=ON"
    "-DENABLE_XHOST=OFF"
    "-DENABLE_OPENMP=ON"
    "-DBUILD_SHARED_LIBS=ON"
    # gau2grid
    "-DCMAKE_INSIST_FIND_PACKAGE_gau2grid=ON"
    "-Dgau2grid_DIR=${gau2grid}/share/cmake/gau2grid"
    # libint
    "-DMAX_AM_ERI=7"
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
    "-DENABLE_libefp=OFF"
    # CheMPS2
    "-DENABLE_CheMPS2=ON"
    "-DCheMPS2_DIR=${chemps2_}"
    # ADCC
    "-DENABLE_adcc=ON"
    # Prefix path for all external packages
    "-DCMAKE_PREFIX_PATH=\"${gau2grid};${libxc};${qcelemental};${pcmsolver_};${dkh_};${chemps2_};${libecpint};${cppe};${adcc}\""
  ];

  format = "other";
  enableParallelBuilding = true;

  configurePhase = ''
    runHook preConfigure

    cmake -Bbuild ${toString cmakeFlags} -DCMAKE_INSTALL_PREFIX=$out
    cd build

    runHook postConfigure
  '';

  postInstall = ''
    # This contains a lot of files that not needed to run the program
    rm -r $out/share/psi4/samples
    rm -r $out/lib/psi4/tests/
  '';

  postFixup =
    let
      binSearchPath = with lib; strings.makeSearchPath "bin" ([ dftd3 ]
        ++ lib.optional enableMrcc mrcc
        ++ lib.optional enableCfour cfour
      );

    in
    ''
      # Make libraries and external binaries available
      wrapProgram $out/bin/psi4 \
        --prefix PATH : ${binSearchPath}

      # Symlinks so that the lib directory is easy to find for python.
      mkdir -p $out/${python.sitePackages}
      ln -s $out/lib/psi4 $out/${python.sitePackages}/.

      # The symlink needs a fix for the PSIDATADIR on python side as its expecting to be installed
      # somewhere else.
      substituteInPlace $out/${python.sitePackages}/psi4/__init__.py \
        --replace 'elif "CMAKE_INSTALL_DATADIR" in data_dir:' 'else:' \
        --replace 'data_dir = os.path.sep.join([os.path.abspath(os.path.dirname(__file__)), "share", "psi4"])' 'data_dir = "@out@/share/psi4"' \
        --subst-var out
    '';

  doInstallCheck = true;
  installCheckPhase = ''
    export OMP_NUM_THREADS=2
    $out/bin/psi4 -i ${testInputs.h2o_omp25_opt} -o h2o_omp25_opt.out -n 2 && grep "7     -76.23508523" h2o_omp25_opt.out
    $out/bin/psi4 -i ${testInputs.BaF2_dft_grad} -o BaF2_dft_grad.out -n 2
  '';

  meta = with lib; {
    description = "Open-Source Quantum Chemistry – an electronic structure package in C++ driven by Python";
    homepage = "http://www.psicode.org/";
    license = licenses.lgpl3;
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
    broken = isPy311;
  };
}
