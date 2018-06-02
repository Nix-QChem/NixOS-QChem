{ nixpkgs ? import (fetchTarball https://nixos.org/channels/nixos-18.03/nixexprs.tar.xz)
, config ? {}
} :

let

  #pkgs = nixpkgs { overlays = [ (import ./default.nix) ]; };
  pkgs = nixpkgs {};
in {
  qdng = pkgs.qdng;

}

