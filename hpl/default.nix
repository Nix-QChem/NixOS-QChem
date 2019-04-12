{ stdenv, fetchurl, openblasCompat, mpi } :

stdenv.mkDerivation rec {
  name = "hpl-${version}";
  version = "2.3";

  src = fetchurl {
    url = "http://www.netlib.org/benchmark/hpl/${name}.tar.gz";
    sha256 = "0c18c7fzlqxifz1bf3izil0bczv3a7nsv0dn6winy3ik49yw3i9j";
  };

  enableParallelBuilding = true;

  buildInputs = [ openblasCompat mpi ];

  postInstall = ''
    # only contains the static lib
    rm -r $out/lib

    install -D testing/ptest/HPL.dat $out/share/hpl/HPL.dat
  '';

  meta = with stdenv.lib; {
    description = "Portable Implementation of the Linpack Benchmark for Distributed-Memory Computers";
    homepage = http://www.netlib.org/benchmark/hpl/;
    platforms = platforms.unix;
    maintainers = [ maintainers.markuskowa ];
  };
}
