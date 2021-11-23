final: prev:

let
  # tested nixpgks-unstable version
  nixpkgsGH = with builtins; (fromJSON (readFile ./flake.lock)).nodes.nixpkgs.locked;

  nixpkgs = import (prev.fetchFromGitHub {
    inherit (nixpkgsGH) owner repo rev;
    sha256 = nixpkgsGH.narHash;
  });

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
