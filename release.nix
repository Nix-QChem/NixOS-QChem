{
  # nixpkgs sources
    nixpkgs ? { outPath = <nixpkgs>; shortRev = "0000000"; }

  # Override config from ENV
  , config ? {}
  , NixOS-QChem ? { shortRev = "0000000"; }
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


    # Make sure we only build the overlay's content
    pkgsClean = with pkgSet.lib;
      filterAttrs (n: v: isDerivation v)
      (builtins.removeAttrs pkgSet."${cfg.prefix}" [
        "pkgs"
        "python2"
        "python3"
        "benchmarksets"
      ]) # release set for python packages
      // makeForPython [ "python2" "python3" ];

  in pkgsClean;

in {
  qchem = pkgs (config // { optAVX = true;}) (self: super: {});
  qchem-mpich = pkgs (config // { optAVX = true;}) (self: super: { mpi = super.mpich; });
  qchem-noavx = pkgs (config // { optAVX = false;}) (self: super: {});
}
