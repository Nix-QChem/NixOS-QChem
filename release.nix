{
  # nixpkgs sources
    nixpkgs ? { outPath = <nixpkgs>; shortRev = "0000000"; }

  # Override config from ENV
  , config ? {}
  # allowUnfree for nixpkgs
  , allowUnfree ? true
  # Additional overlays to apply (applied before and after the main Overlay)
  , preOverlays ? []
  , postOverlays ? []
  # Revision for Hydra
  , NixOS-QChem ? { shortRev = "0000000"; }
  # build more variants
  , buildVariants ? false
  # Build with pinned nixpkgs
  , pin ? true
} :


let

  cfg = (import ./cfg.nix) config;

  nixpkgs-final = if pin then
    import ./nixpkgs-pin.nix (import nixpkgs {})
    else import nixpkgs;

  # use unmodified lib
  inherit (nixpkgs-final {}) lib;

  # Customized package set
  pkgs = config: overlay: let
    pkgSet = nixpkgs-final {
      overlays = [ overlay ] ++ preOverlays ++ [
        (import ./overlay.nix)
      ] ++ postOverlays;

      config = {
        inherit allowUnfree;
        qchem-config = cfg;

        inHydra = true;

        # Provide a handler to sort out unfree Packages
        # This creates a hard fail, which we can test with tryEval v.drvPath
        handleEvalIssue = reason: message:
          if reason == "unfree" then false
          else throw message;

        checkMetaRecursively = false;
        checkMeta = true;
      };
    };

    isBroken = pkg:
      if (pkg ? meta && pkg.meta ? broken) then pkg.meta.broken
      else false;

    makeForPython = plist:
      pkgSet.lib.foldr (a: b: a // b) {}
      (map (x: { "${x}" = hydraJobs pkgSet."${cfg.prefix}"."${x}".pkgs."${cfg.prefix}"; }) plist);

    # Filter out valid derivations
    # Remove broken and unfree if not permitted
    hydraJobs = with lib; filterAttrs (n: v:
      (builtins.tryEval (isDerivation v)).value
      && (if allowUnfree then true else (builtins.tryEval v.drvPath).success)
      && (if isBroken v then (builtins.trace "Warning: ${n} is marked broken." false) else true)
    );

    # Filter Attributes from set by name and put them in a list
    selectList = attributes: pkgs: with lib; mapAttrsToList (n: v: v)
      (filterAttrs (attr: val: (foldr (a: b: a == attr || b) false attributes)) pkgs);

    # Make sure we only build the overlay's content
    pkgsClean = hydraJobs pkgSet."${cfg.prefix}"
      # Pick the test set
      // { tests = hydraJobs pkgSet."${cfg.prefix}".tests; }

      # release set for python packages
      // makeForPython [ "python2" "python3" ]

      # Have a manadatory test set and a channel
      // rec {
        tested = pkgSet.releaseTools.aggregate {
          name = "tested-programs";
          constituents = selectList [
            "molden"
            "sharc"
            "psi4"
            "octave"
            "gromacsMpi"
          ] ( hydraJobs pkgSet."${cfg.prefix}" )
            ++
            selectList [
              "cp2k"
              "nwchem"
              "molcas"
              "molpro"
              "qdng"
              "gaussview"
              "orca"
            ] ( hydraJobs pkgSet."${cfg.prefix}".tests );
        };

        nixexprs = pkgSet.runCommand "nixexprs" {}
          ''
            mkdir -p $out/NixOS-QChem

            cp -r ${./.}/* $out/NixOS-QChem
            cp ${./channel.nix} $out/default.nix

            cat <<EOF > $out/.qchem-revision
            NixOS-QChem ${NixOS-QChem.shortRev}
            EOF
          '';

        channel = pkgSet.releaseTools.channel {
          name = "NixOS-QChem-channel";
          src = nixexprs;
          constituents = [ tested ];
        };
      };

  in pkgsClean;

in {
  "${cfg.prefix}" = pkgs config (self: super: {});

} # Extra variants for testing purposes
// (if buildVariants then {
  "${cfg.prefix}-mpich" = pkgs config (self: super: { mpi = super.mpich; });

  "${cfg.prefix}-mvapich" = pkgs config (self: super: { mpi = self.mvapich; });

  "${cfg.prefix}-mkl" = pkgs config (self: super: {
    blas = super.blas.override { blasProvider = super.mkl; };
    lapack = super.lapack.override { lapackProvider = super.mkl; };
  });

  "${cfg.prefix}-netlib" = pkgs config (self: super: {
    blas = super.blas.override { blasProvider = super.lapack-reference; };
    lapack = super.lapack.override { lapackProvider = super.lapack-reference; };
  });

  "${cfg.prefix}-amd" = pkgs config (self: super: {
    blas = super.blas.override { blasProvider = super.amd-blis; };
    fftw = self.qchem.amd-fftw;
    scalapack = self.qchem.amd-scalapack;
  });
}
else {})
