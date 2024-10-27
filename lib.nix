{ lib } :
{
  # Create a stdenv with CPU optimizations
  makeOptStdenv = stdenv: arch: extraCflags: if arch == null then stdenv else
    stdenv.override {
      name = stdenv.name + "-${arch}";

      # Make sure respective CPU features are set
      hostPlatform = stdenv.hostPlatform //
        lib.mapAttrs (p: a: a arch) lib.systems.architectures.predicates;

      # Add additional compiler flags
      extraAttrs = {
        mkDerivation = args: (stdenv.mkDerivation args).overrideAttrs (old: {
          env.NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "")
            + " -march=${arch} -mtune=${arch} " + extraCflags;
        });
      };
    };

  # generic packages-by-name function:
  # Collect all packages from "dir/*/packages.nix" and apply callPackage {}
  pkgs-by-name = callPackage: dir:
    lib.mapAttrs (pkg: _: callPackage (dir + "/${pkg}/package.nix") {})
    (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir));

  buildEnvMpi = symlinkJoin: input:
    symlinkJoin {
      inherit (input) name;
      paths = lib.flatten (map(x: if x ? passthru.mpi then [ x x.passthru.mpi ] else x) input.paths);
    };
}
