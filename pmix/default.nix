{ stdenv, fetchFromGitHub, perl, autoconf, automake
, libtool, flex, libevent, hwloc, munge, zlib
} :

let
  version = "2.1.4";

in stdenv.mkDerivation {
  name = "pmix-${version}";

  src = fetchFromGitHub {
    repo = "pmix";
    owner = "pmix";
    rev = "v${version}";
    sha256 = "1d1srgdjada8x02w3kp5sxxihcppn14jk6bwkb84mcpwxjnsnhqh";
  };

  nativeBuildInputs = [ perl autoconf automake libtool flex ];

  buildInputs = [ libevent hwloc munge zlib ];

  configureFlags = [
    "--with-libevent=${libevent.dev}"
    "--with-munge=${munge}"
  ];

  preConfigure = ''
    patchShebangs ./autogen.pl
    patchShebangs ./config
    ./autogen.pl
  '';

  enableParallelBuilding = true;

  doCheck = true;

  meta = with stdenv.lib; {
    description = "";
    homepage = https://;
    license = with licenses; gpl2;
    platforms = with platforms; linux ++ darwin;
  };
}

