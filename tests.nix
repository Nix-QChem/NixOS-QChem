let
  qchem = import ./default.nix;
  nixpkgs = import (builtins.fetchGit {
    url = "https://github.com/nixos/nixpkgs";
    name = "nixpkgs-unstable";
    rev = "f18ba0425d8e8cdf9e1d3168e18f1000b2b8e6e6";
    ref = "refs/heads/nixpkgs-unstable";
  }) { overlays = [qchem]; };
in
  nixpkgs
