{ lib, stdenv, requireFile, patchelf, python3
, token
, variant ? "aocl"
} :

assert token != null;
assert lib.elem variant [ "aocl" "mkl" ];

let
  version = "2026.1.0";
  url = "http://www.molpro.net";

in stdenv.mkDerivation {
  pname = "molpro";
  inherit version;

  src = requireFile {
    inherit url;
    name = "molpro-mpp-${version}.linux_x86_64-${variant}.sh.gz";
    sha256 = if (variant == "aocl")
      then "sha256-fSunl7dr+Ngu6u9N4qA4MSnBA2fbCYWYkhBxEOI/7LA="
      else "sha256-1V2pE6GC1uo4u6l3zO4wjt0tWZ11KRKySCff/9zhSJE=";
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

