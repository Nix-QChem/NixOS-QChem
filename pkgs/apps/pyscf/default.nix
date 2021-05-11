{ stdenv, lib, toPythonModule, cmake, fetchFromGitHub, writeTextFile, libcint, libxc, xcfun, blas, numpy,
  scipy, h5py, python
}:
assert
  lib.asserts.assertMsg
  (!blas.isILP64)
  "A 32 bint integer BLAS implementation is required.";

let
  pyscf =
    stdenv.mkDerivation rec {
      pname = "pyscf";
      version = "1.7.6";

      src = fetchFromGitHub {
        owner = "pyscf";
        repo = "pyscf";
        rev = "v${version}";
        sha256 = "1plicf3df732mcwzsinfbmlzwwi40sh2cxy621v7fny2hphh14dl";
      };

      propagatedBuildInputs = [
        python
        numpy
        scipy
        h5py
      ];

      buildInputs = [
        libcint
        libxc
        xcfun
        blas
      ];

      nativeBuildInputs = [
        cmake
      ];

      PYSCF_INC_DIR="${libcint}:${libxc}";

      doCheck = true;

      preConfigure = ''
        cd pyscf/lib
      '';

      cmakeFlags = [
        "-DBUILD_LIBCINT=OFF"
        "-DBUILD_LIBXC=OFF"
        "-DBUILD_XCFUN=OFF"
      ];

      installPhase = ''
        cd ../../..

        mkdir -p $out/lib/${python.libPrefix}/site-packages
        cp -r pyscf $out/lib/${python.libPrefix}/site-packages/.

        mkdir -p $out/lib
        for lib in $out/lib/${python.libPrefix}/site-packages/pyscf/lib/*.so ; do
          ln -s $lib $out/lib/.
        done
      '';

      meta = with lib; {
        description = "Python-based simulations of chemistry framework";
        homepage = https://pyscf.github.io/;
        license = licenses.asl20;
        platforms = platforms.linux;
      };
    };
in
  toPythonModule pyscf
