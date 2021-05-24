{
  description = "NixOS-QChem flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs } : let
      lib = import "${nixpkgs}/lib";

      pkgs = (import nixpkgs) {
        system = "x86_64-linux";
        overlays = [ (import ./default.nix) ];
        config.allowUnfree = true;
        config.qchem-config = (import ./cfg.nix) {
          allowEnv = false;
          optAVX = true;
        };
      };

      pkgsClean = with lib; filterAttrs (n: v: isDerivation v) pkgs.qchem;
  in {

    overlay = import ./.;

    packages."x86_64-linux" = pkgsClean;
    hydraJobs."x86_64-linux" = pkgsClean;
    checks."x86_64-linux" = with lib; filterAttrs (n: v: isDerivation v) pkgs.qchem.tests;
  };
}
