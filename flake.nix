{
  description = "NixOS-QChem flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  nixConfig.extra-substituters = [ "https://nix-qchem.cachix.org" ];

  outputs = { self, nixpkgs } : let
      lib = import "${nixpkgs}/lib";

      pkgs = (import nixpkgs) {
        system = "x86_64-linux";
        overlays = [
          (import ./overlay.nix)
          (self: super: { qchem = super.qchem // {
            turbomole = null;
            cefine = null;
            cfour = null;
            mrcc = null;
            orca = null;
            qdng = null;
            vmd = null;
            mesa-qc = null;
            mcdth = null;
          };})
        ];
        config.allowUnfree = true;
        config.qchem-config = (import ./cfg.nix) {
          allowEnv = false;
          optAVX = true;
        };
      };

      pkgsClean = with lib; filterAttrs (n: isDerivation) pkgs.qchem;
  in {

    overlays = {
      qchem = import ./overlay.nix;
      pythonQchem = import ./pythonPackages.nix pkgs.config.qchem-config.prefix pkgs.config.qchem-config pkgs nixpkgs;
      default = self.overlays.qchem;
    };

    packages."x86_64-linux" = pkgsClean;
    hydraJobs."x86_64-linux" = pkgsClean;
    checks."x86_64-linux" = with lib; filterAttrs (n: isDerivation) pkgs.qchem.tests;
  };
}
