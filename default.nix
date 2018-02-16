let
  # prefer 18.03-pre (master branch)
  pkgs = import (fetchTarball http://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {};

  callPackage = pkgs.lib.callPackageWith (pkgs // pkgs-qc);

  pkgs-qc = with pkgs; {

    molden = pkgs.molden;

    gamess = callPackage ./gamess { mathlib=atlas; };

    gamess-mkl = callPackage ./gamess { mathlib=callPackage ./mkl { } ; useMkl = true; };

    octopus = pkgs.octopus;

    ga = callPackage ./ga {  };

    nwchem = callPackage ./nwchem { };

    openmolcas = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      openblas=openblas;
    };

    qdng = callPackage ./qdng { };

    libfabric = callPackage ./libfabric { };

    mkl = callPackage ./mkl { };

    impi = callPackage ./impi { };

    openshmem = callPackage ./openshmem {};

    openshmem-smp = openshmem;

    openshmem-udp = callPackage ./openshmem { conduit="udp"; };

    openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

    openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

    slurmSpankX11 = pkgs.slurmSpankX11; # make X11 work in srun sessions

    ucx = callPackage ./ucx { };
  };

in pkgs-qc

