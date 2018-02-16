{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, doxygen, numactl, rdma-core
} :

let
  version = "1.2.2";

in stdenv.mkDerivation {
  name = "ucx-${version}";

  src = fetchFromGitHub {
    owner = "openucx";
    repo = "ucx";
    rev = "v${version}";
    sha256 = "0ydxvgxlc31n1rs848m3hmc67ggfxv15xwazw57aiib3pbq29k21";
  };

  nativeBuildInputs = [ autoconf automake libtool doxygen ];
  buildInputs = [ numactl rdma-core  ];

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

