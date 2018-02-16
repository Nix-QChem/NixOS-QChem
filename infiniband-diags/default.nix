{ stdenv, fetchFromGitHub, autoconf, automake
, docutils, libtool, pkgconfig, makeWrapper
, perl, glib, rdma-core, opensm
} :

let
  version = "2.0.0";

in stdenv.mkDerivation {
  name = "infiniband-diags-${version}";

  src = fetchFromGitHub {
    owner = "linux-rdma";
    repo = "infiniband-diags";
    rev = "${version}";
    sha256 = "06x8yy3ly1vzraznc9r8pfsal9mjavxzhgrla3q2493j5jz0sx76";
  };

  nativeBuildInputs = [ autoconf automake libtool docutils pkgconfig makeWrapper ];
  buildInputs = [ glib perl rdma-core opensm ];

  configureFlags = [ "--with-perl-installdir=\${prefix}/lib/perl5/site_perl" ];

  CFLAGS = "-I${opensm}/include/infiniband";

  postPatch = ''
    patchShebangs ./
  '';

  preConfigure = ''
    ./autogen.sh
  '';

  postInstall = ''
    rm -r $out/var
  '';

  postFixup = ''
    for pls in `find $out/bin -name "*.pl"`; do
      echo "wrapping $pls"
      wrapProgram $pls --prefix PERL5LIB : "$out/lib/perl5/site_perl"
    done
  '';

  meta = with stdenv.lib; {
    description = "Infiniband diagnostic tools";
    homepage = https://github.com/linux-rdma/infiniband-diags;
    license = licenses.gpl2;
    maintainers = with maintainers; [ markuskowa ];
    platforms = platforms.linux;
  };
}

