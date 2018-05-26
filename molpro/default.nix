{ stdenv, fetchurl, requireFile, python
, srcurl ? null
, token
} :
let
  version = "2015.1.33";
  srcfile = "molpro-mpp-${version}.linux_x86_64_openmp.sh.gz";
  sha256 = "1y9fjky7vl8lrgxvr2lxycihyi2kxwyilzf2jdvfla68jk1wlwf3";

in stdenv.mkDerivation {
  name = "molpro-${version}";

  src = if srcurl != null then
    fetchurl {
      url = srcurl + "/" + srcfile;
      sha256 = sha256;
    }
  else
    requireFile {
     name = srcfile;
     url = http://www.molpro.net;
     inherit sha256;
   };

   buildInputs = [ python ];

  unpackPhase = ''
    mkdir -p source
    gzip -d -c $src > source/install.sh
    cd source
  '';

  postPatch = ''
    sed -i "1,/_EOF_/s:/bin/pwd:pwd:" install.sh
  '';

  configurePhase = ''
    export MOLPRO_KEY="${token}"
  '';

  installPhase = ''
    sh install.sh -batch -prefix $out
  '';

  dontStrip = true;

  meta = with stdenv.lib; {
    description = "Quantum program package";
    homepage = https://www.molpro.net;
    licenses = licences.unfree;
    platforms = [ "x86_64-linux" ];
  };
}

