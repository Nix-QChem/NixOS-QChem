{ stdenv, lib, pkgs, fetchurl, cmake, gfortran, blas
, mpi ? pkgs.openmpi, ssh ? pkgs.openssh
} :

# ILP64 version is defunct

let
  version = "2.0.2";

  blasName = (builtins.parseDrvName blas.name).name;

in stdenv.mkDerivation {
  name = "scalapack-${version}" + lib.optionalString (blasName != "openblas") "-${blasName}";

  src = fetchurl {
    url = "http://www.netlib.org/scalapack/scalapack-${version}.tgz";
    sha256 = "0p1r61ss1fq0bs8ynnx7xq4wwsdvs32ljvwjnx6yxr8gd6pawx0c";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ gfortran mpi ssh blas ];

  enableParallelBuilding = true;

  doCheck = true;

  CFLAGS = "-O3 -mavx";
  FFLAGS = "-O3 -mavx";

  preConfigure = ''
    cmakeFlagsArray+=( -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=ON
      -DLAPACK_LIBRARIES=${if blasName == "openblas" then "-lopenblas"
         else "'-lmkl_gf_lp64 -lmkl_sequential -lmkl_core'"}
      -DBLAS_LIBRARIES=${if blasName == "openblas" then "-lopenblas"
         else "'-lmkl_gf_lp64 -lmkl_sequential -lmkl_core'"}
      )
  '';

  checkPhase = ''
    # make sure the test starts even if we have less than 4 cores
    export OMPI_MCA_rmaps_base_oversubscribe=1

    # Run single threaded
    export OMP_NUM_THREADS=1

    sed -i "s/TimeOut: 1500/TimeOut: 3600/" DartConfiguration.tcl

    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/lib
    export CTEST_OUTPUT_ON_FAILURE=1

    make test
  '';

  meta = with stdenv.lib; {
    description = "Scalable linear algebra package";
    homepage = http://www.netlib.org/scalapack;
    license = licenses.bsd;
    platforms = platforms.linux;
  };
}

