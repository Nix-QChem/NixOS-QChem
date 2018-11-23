{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, doxygen, numactl, rdma-core, libbfd, libiberty, perl
, zlib
# Enable machine-specific optimizations
, enableOpt ? false
} :

let
  version = "1.4.0";

in stdenv.mkDerivation {
  name = "ucx-${version}";

  src = fetchFromGitHub {
    owner = "openucx";
    repo = "ucx";
    rev = "v${version}";
    sha256 = "0p126wd8xd7x1fwc78hqmaaykyxyn8kpxd69i549d5c9w2a75j8y";
  };

  nativeBuildInputs = [ autoconf automake libtool doxygen ];

  buildInputs = [ numactl rdma-core libbfd libiberty perl zlib ];

  configureFlags = [ "--with-rdmacm=${rdma-core}" ]
    ++ stdenv.lib.optionals enableOpt  [
      "--with-avx"
      "--with-sse41"
      "--with-sse42"
    ];

  enableParallelBuilding = true;

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with stdenv.lib; {
    description = "Unified Communication X library";
    homepage = http://www.openucx.org;
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}

