pkgs:

let
  # tested nixpgks-unstable version
  nixpkgsGH = with builtins; (fromJSON (readFile ./flake.lock)).nodes.nixpkgs.locked;

in import (pkgs.fetchFromGitHub {
  inherit (nixpkgsGH) owner repo rev;
  sha256 = nixpkgsGH.narHash;
})
