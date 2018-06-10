{ stdenv, pkgs, fetchFromGitHub, autoconf, automake, libtool
, python, boost, mpi ? pkgs.openmpi, libxc, fetchpatch, openblas
, scalapack, makeWrapper, openssh
} :

let
  version = "1.1.1";

  mpiName = (builtins.parseDrvName mpi.name).name;
  mpiType = if mpiName == "openmpi" then mpiName
       else if mpiName == "mpich"  then "mvapich"
       else if mpiName == "mvapich"  then mpiName
       else throw "mpi type ${mpiName} not supported";

in stdenv.mkDerivation {
  name = "bagel-${version}";

  src = fetchFromGitHub {
    owner = "nubakery";
    repo = "bagel";
    rev = "v${version}";
    sha256 = "1yxkhqd9rng02g3zd7c1b32ish1b0gkrvfij58v5qrd8yaiy6pyy";
  };

  nativeBuildInputs = [ autoconf automake libtool openssh ];
  buildInputs = [ python boost libxc openblas scalapack mpi ];

  CXXFLAGS="-DNDEBUG -O3 -mavx -lopenblas";

  configureFlags = [ "--with-libxc" "--with-mpi=${mpiType}" ];

  outputs = [ "out" "tests" ];

  postPatch = ''
    # Fixed upstream
    sed -i '/using namespace std;/i\#include <string.h>' src/util/math/algo.cc
  '';

  preConfigure = ''
    ./autogen.sh
  '';

  enableParallelBuilding = true;

  postInstall = ''
    cat << EOF > $out/bin/bagel
    if [ \$# -lt 1 ]; then
    echo
    echo "Usage: `basename \\$0` [mpirun parameters] <input file>"
    echo
    exit
    fi
    ${mpi}/bin/mpirun \''${@:1:\$#-1} $out/bin/BAGEL \''${@:\$#}
    EOF
    chmod 755 $out/bin/bagel

    # copy test jobs
    mkdir -p $tests/
    cp test/* $tests 
  '';

  installCheckPhase = ''
    echo "Running HF test"
    export OMP_NUM_THREADS=1
    export MV2_ENABLE_AFFINITY=0 
    mpirun -np 1 $out/bin/BAGEL test/hf_svp_hf.json > log
    echo "Check output"
    grep "SCF iteration converged" log
    grep "99.847790" log
  '';

  doInstallCheck = true;

  doCheck = true;

  meta = with stdenv.lib; {
    description = "Brilliantly Advanced General Electronic-structure Library";
    homepage = http://www.shiozaki.northwestern.edu/bagel.php;
    license = licenses.gpl3;
    maintainers = maintainers.markuskowa;
    platforms = platforms.linux;
  };
}

