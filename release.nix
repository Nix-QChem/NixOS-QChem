{
  # nixpkgs sources
    nixpkgs ? { outPath = <nixpkgs>; shortRev = "0000000"; }

  # Override config from ENV
  , config ? {}
  , NixOS-QChem ? { shortRev = "0000000"; }
  # build more variants
  , buildVariants ? false
} :


let

  cfg = (import ./cfg.nix) config;

  # Customized package set
  pkgs = config: overlay: let
    pkgSet = (import nixpkgs) {
      overlays = [ overlay (import ./default.nix) ];
      config.allowUnfree = true;
      config.qchem-config = cfg;
    };

    makeForPython = plist:
      pkgSet.lib.foldr (a: b: a // b) {}
      (map (x: { "${x}" = pkgSet."${cfg.prefix}"."${x}".pkgs."${cfg.prefix}"; }) plist);

    # Filter out derivations
    hydraJobs = with pkgSet.lib; filterAttrs (n: v: isDerivation v);

    # Make sure we only build the overlay's content
    pkgsClean = hydraJobs pkgSet."${cfg.prefix}"
      # Pick the test set
      // { tests = hydraJobs pkgSet."${cfg.prefix}".tests; }
      # release set for python packages
      // makeForPython [ "python2" "python3" ];

  in pkgsClean;

in {
  qchem = pkgs (config // { optAVX = true; }) (self: super: {});
  qchem-noavx = pkgs (config // { optAVX = false; }) (self: super: {});
} // (if buildVariants then {
  qchem-mpich = pkgs (config // { optAVX = true; }) (self: super: { mpi = super.mpich; });

  qchem-mkl = pkgs (config // { optAVX = true; }) (self: super: {
    blas = super.blas.override { blasProvider = super.mkl; };
    lapack = super.lapack.override { lapackProvider = super.mkl; };
  });

  qchem-amd = pkgs (config // { optAVX = true; }) (self: super: {
    blas = super.blas.override { blasProvider = super.amd-blis; };
    lapack = super.lapack.override { lapackProvider = super.amd-libflame; };
  });
}
else {})
