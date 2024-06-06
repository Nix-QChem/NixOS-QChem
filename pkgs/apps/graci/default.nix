{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  gfortran,
  blas,
  lapack,
  hdf5-fortran,
  makeWrapper,
  python3,
}:

let
  common = {
    pname = "graci";
    version = "20231004";

    src = fetchFromGitHub {
      owner = "schuurman-group";
      repo = "graci";
      rev = "583d503f11b85a5311e968bb66456987e5d7ddd2";
      hash = "sha256-ERN29NUcLpKFMGjfZTx8eWskgS5R21oMc0/pD4Id2g4=";
    };

    meta = with lib; {
      description = "General Reference Configuration Interaction package";
      license = licenses.lgpl21Only;
      maintainers = [ maintainers.markuskowa ];
      platforms = platforms.linux;
    };
  };

  overlap = stdenv.mkDerivation (
    finalAttrs:
    (
      common
      // {
        pname = common.pname + "-" + "overlap";
        preConfigure = "cd graci/dep/overlap";

        nativeBuildInputs = [
          cmake
          gfortran
        ];
        buildInputs = [
          blas
          lapack
        ];
      }
    )
  );

  bitci = stdenv.mkDerivation (
    finalAttrs:
    (
      common
      // {
        pname = common.pname + "-" + "bitci";
        preConfigure = "cd graci/dep/bitci;";

        enableParallelBuilding = false;

        nativeBuildInputs = [
          cmake
          gfortran
        ];
        buildInputs = [
          hdf5-fortran
          overlap
          blas
          lapack
        ];

        cmakeFlags = [
          "-DHDF5_INC_DIR=${lib.getDev hdf5-fortran}/include"
        ];
      }
    )
  );
in
python3.pkgs.buildPythonApplication (
  common
  // {
    propagatedBuildInputs = with python3.pkgs; [
      pyscf
      numpy
      sympy
    ];

    patches = [ ./lib-path.patch ];

    postPatch = ''
      for i in core/libs.py utils/basis.py; do
        substituteInPlace graci/$i --replace-fail '@GRACI@' "$out"
      done
    '';

    preBuild = ''
      cat <<EOF > setup.py
      from setuptools import setup
      setup(
        name='${common.pname}',
        version='1.0',
        packages=[
          'graci/core',
          'graci/interaction',
          'graci/interfaces/bitci',
          'graci/interfaces/overlap',
          'graci/io',
          'graci/methods',
          'graci/properties',
          'graci/tools',
          'graci/utils'
        ],
        scripts=[
          'bin/graci',
          'bin/gplot',
          'bin/gmerge',
          'bin/glabel',
          'bin/gextract',
          'bin/bddinp'
        ]
      )
      EOF
    '';

    postInstall = ''
      ln -s ${overlap}/lib/liboverlap.so $out/lib/
      for i in ci si wf; do
        ln -s ${bitci}/lib/libbit$i.so $out/lib/
      done

      mkdir -p $out/share/graci/basis_sets
      cp graci/utils/basis_sets/* $out/share/graci/basis_sets/
    '';
  }
)
