updPath: basePath:

let
  releaseOpts = {
    config = { };
    allowUnfree = false;
    preOverlays = [ ];
    postOverlays = [
      (final: prev: {
        turbomole = null;
        cefine = null;
        cfour = null;
        gamess-us = null;
        mrcc = null;
        orca = null;
        qdng = null;
        vmd = null;
        mesa-qc = null;
        mcdth = null;
        nixGL = null;
      })
    ];
    buildVariants = false;
    pin = true;
  };

  pkgs = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-22.11.tar.gz") { };

  inherit (pkgs) lib;

  # Ignored outputs, to be removed additionally from the attribute set.
  auxIgnore = [
    "channel"
    "nixexprs"
    "tested"
  ];

  # Recursive, flattened difference of attribute sets.
  recAttrSetDiff = l: r: lib.attrsets.filterAttrsRecursive
    (lK: lV: !(builtins.elem lK auxIgnore) && (if lib.hasAttr lK r
    then lV != r."${lK}"
    else true)
    )
    l
  ;

  # Simplify package set
  simplify = as: with lib.attrsets; mapAttrs (_: v: v.drvPath) (filterAttrs (_: v: isDerivation v) as);

  # Get packages from the updated and base versions
  updPkgs = (import "${updPath}/release.nix" releaseOpts).qchem;
  basPkgs = (import "${basePath}/release.nix" releaseOpts).qchem;

  # We are not interested in the realised packages, the derivation paths are
  # enough and save a lot of time.
  updDerivs = simplify updPkgs;
  basDerivs = simplify basPkgs;

  # Handle python packages separately to avoid recursion errors with filterAttrsRecursive
  updPyDerivs = simplify updPkgs.python3;
  basPyDerivs = simplify basPkgs.python3;

  # Changed derivations in update
  changedDerivs = recAttrSetDiff updDerivs basDerivs;
  changedPyDerivs = recAttrSetDiff updPyDerivs basPyDerivs;

  # For CI purposes we only require the changed attribute keys.
in
{
  topLevel = builtins.attrNames changedDerivs;
  python3 = builtins.attrNames changedPyDerivs;
}

