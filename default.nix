final: prev:

let
  nixpkgs = import ./nixpkgs-pin.nix prev;

  cfg =
    if (builtins.hasAttr "qchem-config" prev.config) then
      (import ./cfg.nix) prev.config.qchem-config
    else
      (import ./cfg.nix) { allowEnv = true; }; # if no config is given allow env

  pkgs = nixpkgs {
    overlays = [ (import ./overlay.nix) ];
    inherit (prev) config system;
  };

in
{
  "${cfg.prefix}" = pkgs."${cfg.prefix}";
}
