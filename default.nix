final: prev:

let
  nixpkgs = import ./nixpkgs-pin.nix prev;

  cfg =
    if (builtins.hasAttr "qchem-config" prev.config) then
      (import ./cfg.nix) prev.config.qchem-config
    else
      (import ./cfg.nix) { allowEnv = true; }; # if no config is given allow env

  # Turn on CUDA in nixpkgs based on qchem settings
  config = prev.config // {
    cudaSupport = cfg.useCuda or false;
  };

  pkgs = nixpkgs {
    overlays = [ (import ./overlay.nix) ];
    inherit (prev) system;
    inherit config;
  };

in
{
  "${cfg.prefix}" = pkgs."${cfg.prefix}";
}
