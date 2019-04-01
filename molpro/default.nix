{ stdenv, requireFile, fetchurl, python, token
} :
let
  version = "2019.1.0";

in stdenv.mkDerivation {
  name = "molpro-${version}";

  src = requireFile {
    url = http://www.molpro.net;
    name = "molpro-mpp-${version}.linux_x86_64_openmp.sh.gz";
    sha256 = "1g2nrr12grdlq4chsg15vhfyar7rgyy84d73pfdxb34vi2r1aw6s";
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

