{ stdenv, fetchurl, rdma-core, bison, flex } :

let
  version = "3.3.20";

in stdenv.mkDerivation {
  name = "opensm-${version}";

  src = fetchurl {
    url = "https://www.openfabrics.org/downloads/management/opensm-${version}.tar.gz";
    sha256 = "162sg1w7kgy8ayl8a4dcbrfacmnfy2lr9a2yjyq0k65rmd378zg1";
  };

  nativeBuildInputs = [ bison flex ];
  buildInputs = [ rdma-core ];

  meta = with stdenv.lib; {
    description = "Infinband subnet manager";
    homepage = http://openfabrics.org;
    maintainers = with maintainers; [ markuskowa ];
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}

