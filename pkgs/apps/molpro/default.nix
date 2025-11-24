{ lib, stdenv, requireFile, patchelf, python3
, token
} :

assert token != null;

let
  version = "2025.4.1";
  url = "http://www.molpro.net";

in stdenv.mkDerivation {
  pname = "molpro";
  inherit version;

  src = requireFile   {
    inherit url;
    name = "molpro-mpp-${version}.linux_x86_64.sh.gz";
    sha256 = "sha256-nWMj2Jro1+R7YO/AfM29F3X5rDQQHzHDk2KwYOShQbY=";
  };

  nativeBuildInputs = [ patchelf ];
  buildInputs = [ python3 ];

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

  postFixup = ''
    for bin in molpro.exe; do
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/$bin
    done
    for bin in hydra_pmi_proxy mpiexec mpiexec.hydra hydra_bstrap_proxy; do
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/impi/bin/$bin
    done
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    #
    # Minimal check if installation runs properly
    #
    inp=water

    cat << EOF > $inp.inp
    basis=STO-3G
    geom = {
    3
    Angstrom
    O       0.000000  0.000000  0.000000
    H       0.758602  0.000000  0.504284
    H       0.758602  0.000000 -0.504284
    }
    HF
    EOF

    # pretend this is a writable home dir
    export HOME=$PWD

    $out/bin/molpro $inp.inp

    echo "Check for successful run:"
    grep "RHF STATE 1.1 Energy" $inp.out
    echo "Check for correct energy:"
    grep "RHF STATE 1.1 Energy" $inp.out | grep 74.880174

  '';

  meta = with lib; {
    description = "Quantum chemistry program package";
    homepage = url;
    license = licenses.unfree;
    maintainers = [ maintainers.markuskowa ];
    platforms = [ "x86_64-linux" ];
  };
}

