{ stdenv, fetchFromGitHub, autoconf, automake, libtool
, rdma-core, libnl
} :

let
  version = "1.5.3";

in stdenv.mkDerivation {
  name = "libfabric-${version}";

  src = fetchFromGitHub {
    owner = "ofiwg";
    repo = "libfabric";
    rev = "v${version}";
    sha256 = "06igaak1jzz6kyhjahkglx6pxcll2b18a8bajynnr6plcgz6fb8h";
  };

  nativeBuildInputs = [ autoconf automake libtool ];
  buildInputs = [ rdma-core libnl ];

  configureFlags = [ "--with-libnl=${libnl.dev}" ];

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with stdenv.lib; {
    description = "OpenFabrics Interfaces (OFI) framework";
    homepage = https://ofiwg.github.io/libfabric;
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}

