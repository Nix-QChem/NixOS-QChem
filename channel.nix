#
# Template for a channel's default.nix
#
{
  system ? builtins.currentSystem
, overlays ? []
, config ? {}
} :

import ./nixpkgs {
  inherit system config;
  overlays = [ (import ./NixOS-QChem) ] ++  overlays;
}
