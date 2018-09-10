{ stdenv, fetchurl, mpi } :
let
  version = "5.4.3";

in stdenv.mkDerivation {
  name = "osu-benchmark-${version}";

  src = fetchurl {
    url = "http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${version}.tar.gz";
    sha256 = "03a9j14sdr4npcj1qf98v0pjj5q7mfsqlg9q6mbnz3idd4vk24is";
  };

  nativeBuildInputs = [ mpi ];
  buildInputs = [ ];

  preConfigure = ''
   export CXX="${mpi}/bin/mpicc"
   export CC="${mpi}/bin/mpicxx"
  '';

  buildPhase = "make";

  meta = with stdenv.lib; {
    description = "";
    homepage = https://;
    license = with licenses; gpl2;
    platforms = with platforms; linux;
  };
}

