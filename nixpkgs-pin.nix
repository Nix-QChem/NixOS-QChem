let
  # tested nixpgks-unstable version
  nixpkgsFlake = with builtins; (fromJSON (readFile ./flake.lock)).nodes.nixpkgs.locked;

in import (builtins.fetchTarball {
  inherit (nixpkgsFlake) url;
  sha256 = nixpkgsFlake.narHash;
})
