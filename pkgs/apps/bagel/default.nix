{ stdenv, lib, fetchFromGitHub, autoconf, automake, libtool
, makeWrapper, openssh, fetchpatch
, python3, boost, blas, lapack
, enableMpi ? true
, mpi
, enableScalapack ? enableMpi
, scalapack
} :

let
  mpiName = mpi.pname;
  mpiType = if mpiName == "openmpi" then mpiName
       else if mpiName == "mpich"  then "mvapich"
       else if mpiName == "mvapich"  then mpiName
       else throw "mpi type ${mpiName} not supported";

  useMKL = blas.passthru.implementation == "mkl" && lapack.passthru.implementation == "mkl";

in stdenv.mkDerivation rec {
  pname = "bagel";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "nubakery";
    repo = "bagel";
    rev = "v${version}";
    sha256 = "184p55dkp49s99h5dpf1ysyc9fsarzx295h7x0id8y0b1ggb883d";
  };

  # Required for gcc >= 10
  patches = [ (fetchpatch {
    name = "gcc-11";
    url = "https://salsa.debian.org/debichem-team/bagel/-/raw/629c8b4869c707cae76503706806f09c132c6883/debian/patches/fix_gcc_11_build_failure.patch";
    sha256 = "0kvnlzs5ili4l728z8rirhn5xf4c30cabiijzzivcjxqbvxdb8b0";
  })];

  nativeBuildInputs = [ autoconf automake libtool openssh boost ];
  buildInputs = [
    python3
    boost
  ] ++ (if useMKL then [ blas.passthru.provider ] else [ blas lapack ])
    ++ lib.optional enableMpi mpi
    ++ lib.optional enableScalapack scalapack;

  propagatedBuildInputs = lib.optional enableMpi [ mpi ];
  propagatedUserEnvPkgs = lib.optional enableMpi [ mpi ];

  #
  # Furthermore, if relativistic calculations fail without MKL,
  # users may consider reconfiguring and recompiling with -DZDOT_RETURN in CXXFLAGS.
  CXXFLAGS = builtins.toString ([
    "-DNDEBUG"
    "-O3"
    "-DCOMPILE_J_ORB"
  ] ++ lib.lists.optionals (!useMKL) [ "-lblas" "-llapack" ]
    ++ lib.lists.optional (blas.passthru.implementation == "openblas") "-DZDOT_RETURN"
  );

  BOOST_ROOT=boost;

  configureFlags = with lib; [ "--with-boost=${boost}" ]
                   ++ optional enableMpi "--with-mpi=${mpiType}"
                   ++ optional ( !enableMpi ) "--disable-smith"
                   ++ optional ( !enableScalapack ) "--disable-scalapack"
                   ++ optional ( useMKL ) "--enable-mkl";

  postPatch = ''
    # Fixed upstream
    sed -i '/using namespace std;/i\#include <string.h>' src/util/math/algo.cc
  '';

  preConfigure = ''
    ./autogen.sh
  '';

  enableParallelBuilding = true;

  postInstall = ''
    # install test jobs
    mkdir -p $out/share/tests
    cp test/* $out/share/tests
  '';

  installCheckPhase = ''
    echo "Running HF test"
    export OMP_NUM_THREADS=1
    export OMPI_MCA_rmaps_base_oversubscribe=1
    export MV2_ENABLE_AFFINITY=0
    # Fix to make mpich run in a sandbox
    export HYDRA_IFACE=lo

    ${if (enableMpi) then "mpirun -np 1 $out/bin/BAGEL test/hf_svp_hf.json > log"
    else "$out/bin/BAGEL test/hf_svp_hf.json > log"}

    echo "Check output"
    grep "SCF iteration converged" log
    grep "99.847790" log
  '';

  doInstallCheck = true;

  doCheck = true;

  passthru = lib.optionalAttrs enableMpi { inherit mpi; };

  meta = with lib; {
    description = "Brilliantly Advanced General Electronic-structure Library";
    homepage = "https://nubakery.org";
    license = licenses.gpl3;
    maintainers = [ maintainers.markuskowa ];
    platforms = [ "x86_64-linux" ];
  };
}
