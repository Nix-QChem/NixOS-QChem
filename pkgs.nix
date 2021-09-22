let
  pkgs = import (builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs.git";
    rev = "bca7162d606e7b5fd1d1fe9324fed5d645624c5c";
    ref = "nixpkgs-unstable";
  }) {
    overlays = [ (import ./default.nix) ];
    config = {
      qchem-config = {
        optAVX = false;
        optArch = null;
      };
    };
  };
in pkgs
