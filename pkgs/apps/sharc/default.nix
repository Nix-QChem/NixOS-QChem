{ stdenv
, lib
, sharc-unwrapped
, makeWrapper
, enableMolcas ? false
, molcas
, enableBagel ? false
, bagel
, enableOrca ? false
, orca
, enableGaussian ? false
, gaussian
, enableTurbomole ? false
, turbomole
, enableMolpro ? false
, molpro
}:

stdenv.mkDerivation {
  inherit (sharc-unwrapped) pname version meta;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    for i in $(find ${lib.getBin sharc-unwrapped}/bin -type f); do
      local_name="$out/bin/$(basename $i)"
      ln -s $i $local_name
      wrapProgram $local_name \
        --set SHARC $out/bin \
        --set LD_LIBRARY_PATH "$LD_LIBRARY_PATH" \
        --set HOSTNAME localhost \
        --prefix PYTHONPATH : "${lib.getBin sharc-unwrapped}/${sharc-unwrapped.python.sitePackages}" \
        ${lib.optionalString enableMolcas "--set-default MOLCAS ${lib.getBin molcas}"} \
        ${lib.optionalString enableBagel "--set-default BAGEL ${lib.getBin bagel}"} \
        ${lib.optionalString enableMolpro "--set-default MOLPRO ${lib.getBin molpro}/bin"} \
        ${lib.optionalString enableOrca "--set-default ORCADIR ${lib.getBin orca}/bin"} \
        ${lib.optionalString enableTurbomole "--set-default TURBOMOLE ${lib.getBin turbomole}/bin"} \
        ${lib.optionalString enableGaussian "--set-default GAUSSIAN ${lib.getBin gaussian}/bin"}
    done

    runHook postInstall
  '';

  setupHooks = [
    ./sharcHook.sh
  ];

}
