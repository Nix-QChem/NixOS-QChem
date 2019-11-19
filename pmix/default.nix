{ stdenv, fetchFromGitHub, perl, autoconf, automake
, libtool, flex, libevent, munge, zlib
} :

let
  version = "2.2.3";

in stdenv.mkDerivation {
  name = "pmix-${version}";

  src = fetchFromGitHub {
    repo = "openpmix";
    owner = "openpmix";
    rev = "v${version}";
    sha256 = "0vmikw71hd35h86mzyrfpc6z3mfi503nx834gz596agvcqrd62si";
  };

  nativeBuildInputs = [ perl autoconf automake libtool flex ];

  buildInputs = [ libevent munge zlib ];

  configureFlags = [
    "--with-libevent=${libevent.dev}"
    "--with-munge=${munge}"
    "--enable-pmix-binaries"
  ];

  preConfigure = ''
    patchShebangs ./autogen.pl
    patchShebangs ./config
    ./autogen.pl
  '';

  enableParallelBuilding = true;

  doCheck = true;

  meta = with stdenv.lib; {
    description = "Process management interface for HPC environments";
    homepage = "https://pmix.org";
    license = licenses.bsd3;
    maintainers = [ maintainers.markuskowa ];
    platforms = with platforms; linux ++ darwin;
  };
}

