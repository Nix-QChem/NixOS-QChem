{ stdenv, fetchurl, mpi } :
let
  version = "5.4.3";

in stdenv.mkDerivation {
  name = "osu-benchmark-${version}";

  src = fetchurl {
    url = "http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${version}.tar.gz";
    sha256 = "03a9j14sdr4npcj1qf98v0pjj5q7mfsqlg9q6mbnz3idd4vk24is";
  };

  buildInputs = [ mpi ];

  preConfigure = ''
    export CXX="${mpi}/bin/mpicc"
    export CC="${mpi}/bin/mpicxx"
  '';

  postInstall = ''
    mkdir $out/bin

    cat > $out/bin/osu_run_all << EOF
    #!${stdenv.shell}
    for i in `find $out/libexec -type f | tr '\n' ' '`; do
      ${mpi}/bin/mpirun -np 2 \$i
    done
    EOF
  '';

  meta = with stdenv.lib; {
    description = "MPI micro benchmark suite";
    homepage = http://mvapich.cse.ohio-state.edu/benchmarksi;
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}

