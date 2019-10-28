let
  # getEnv that returns null if var is not set
  getEnv = x:
  let
    envVar = builtins.getEnv x;
  in
    if (builtins.stringLength envVar) > 0 then envVar
    else null;

in {
  # base url for non-free packages
  srcurl = getEnv "NIXQC_SRCURL";

  # path to packages that reside outside the nix store
  optpath = getEnv "NIXQC_OPTPATH";

  # string containing a valid MOLPRO license token
  licMolpro = getEnv "NIXQC_LICMOLPRO";

  # turn of AVX optimizations in selected packages
  optAVX = if getEnv "NIXQC_AVX" == "1" then true else false;
}
