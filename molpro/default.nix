{ stdenv, localFile, fetchurl, requireFile, python
, srcurl ? null
, token
} :
let
  version = "2018.1.1";

in stdenv.mkDerivation {
  name = "molpro-${version}";

  src = localFile {
    website = http://www.molpro.net;
    srcfile = "molpro-mpp-${version}.linux_x86_64_openmp.sh.gz";
    sha256 = "19i89bjkznrv0na7wjj5bhb28lyp9360pr575nvp8acxsavny0ic";
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
    description = "Quantum chemistry program package";
    homepage = https://www.molpro.net;
    licenses = licences.unfree;
    maintainers = [ maintainers.markuskowa ];
    platforms = [ "x86_64-linux" ];
  };
}

