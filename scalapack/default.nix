{ stdenv, pkgs, fetchurl, cmake, gfortran, openblas
, mpi ? pkgs.openmpi, ssh ? pkgs.openssh
} :

#assert openblas.blas64 -> mpi.ILP64 == true;

let
  version = "2.0.2";

in stdenv.mkDerivation {
  name = "scalapack-${version}";

  src = fetchurl {
    url = "http://www.netlib.org/scalapack/scalapack-${version}.tgz";
    sha256 = "0p1r61ss1fq0bs8ynnx7xq4wwsdvs32ljvwjnx6yxr8gd6pawx0c";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ gfortran mpi ssh openblas ];

  enableParallelBuilding = true;

  doCheck = true;

  inherit (openblas) blas64;

  preConfigure = ''
    cmakeFlagsArray+=( -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=ON
      -DLAPACK_LIBRARIES="-L${openblas}/lib -lopenblas"
      -DBLAS_LIBRARIES="-L${openblas}/lib -lopenblas"
      -DCMAKE_Fortran_FLAGS=${if openblas.blas64 then "-fdefault-integer-8" else ""}
      )
  '';

  checkPhase = ''
    # make sure the test starts even if we have less than 4 cores
    export OMPI_MCA_rmaps_base_oversubscribe=1

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

