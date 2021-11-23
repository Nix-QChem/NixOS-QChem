final: prev:

let
  # tested nixpgks-unstable version
  version = with builtins; (fromJSON (readFile ./flake.lock)).nodes.nixpkgs.locked.rev;

  nixpkgs = import (builtins.fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/${version}.tar.gz"
  );

  cfg =
    if (builtins.hasAttr "qchem-config" prev.config) then
      (import ./cfg.nix) prev.config.qchem-config
    else
      (import ./cfg.nix) { allowEnv = true; }; # if no config is given allow env

  pkgs = nixpkgs {
    overlays = [ (import ./overlay.nix) ];
    inherit (prev) config;
  };

in
{
  "${cfg.prefix}" = pkgs."${cfg.prefix}";
}
