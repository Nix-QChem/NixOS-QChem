{ lib, stdenv, requireFile, patchelf, python3
, token
, comm ? "sockets"
} :

assert token != null;
assert (comm == "sockets") || (comm == "mpipr");

let
  version = "2024.3.0";
  url = "http://www.molpro.net";

in stdenv.mkDerivation {
  pname = "molpro";
  inherit version;

  src = requireFile (if comm == "sockets" then {
    inherit url;
    name = "molpro-mpp-${version}.linux_x86_64_sockets.sh.gz";
    sha256 = "sha256-3yhUfo/2xYqO8Y22KKpja1kO2JpuV7/lsOBFamOxNUQ=";
  } else {
    inherit url;
    name = "molpro-mpp-${version}.linux_x86_64_mpipr.sh.gz";
    sha256 = "sha256-mhBhz6SIbbtZ1LcL+sEo33htkVOHYjamPh5db8xPzEs=";
  });

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
    #
    # Since version 2019.1 the binaris are dynamically linked
    for bin in ${lib.optionalString (comm == "sockets") "hydra_pmi_proxy mpiexec"} molpro.exe; do
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/$bin
    done
    '' + lib.optionalString (comm == "mpipr") ''
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
    # need to specify interface or: "MPID_nem_tcp_init(373) gethostbyname failed"
    ${lib.optionalString (comm == "sockets") ''
      $out/bin/molpro --launcher \
        "$out/bin/mpiexec -iface lo $out/bin/molpro.exe" $inp.inp
    ''}
    ${lib.optionalString (comm == "mpipr") ''
      $out/bin/molpro --launcher \
        $out/bin/molpro.exe $inp.inp
    ''}

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

