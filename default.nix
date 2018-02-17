let
  # prefer 18.03-pre (master branch)
  pkgs = import (fetchTarball http://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {};

  callPackage = pkgs.lib.callPackageWith (pkgs // pkgs-qc);

  pkgs-qc = with pkgs; {

    ### Quantum Chem
    cp2k = callPackage ./cp2k { };

    molden = pkgs.molden;

    gamess = callPackage ./gamess { mathlib=atlas; };

    gamess-mkl = callPackage ./gamess { mathlib=callPackage ./mkl { } ; useMkl = true; };

    ga = callPackage ./ga { ssh=openssh; };

    libxc = pkgs.libxc;

    nwchem = callPackage ./nwchem { };

    octopus = pkgs.octopus;

    openmolcas = callPackage ./openmolcas {
      texLive = texlive.combine { inherit (texlive) scheme-basic epsf cm-super; };
      openblas=openblas;
    };

    qdng = callPackage ./qdng { };

    ### HPC libs and Tools

    ibsim = callPackage ./ibsim { };

    impi = callPackage ./impi { };

    infiniband-diags = callPackage ./infiniband-diags { };

    libfabric = callPackage ./libfabric { };

    libint = callPackage ./libint { };

    mkl = callPackage ./mkl { };

    openshmem = callPackage ./openshmem {};

    openshmem-smp = openshmem;

    openshmem-udp = callPackage ./openshmem { conduit="udp"; };

    openshmem-ibv = callPackage ./openshmem { conduit="ibv"; };

    openshmem-ofi = callPackage ./openshmem { conduit="ofi"; };

    opensm =  callPackage ./opensm { };

    slurmSpankX11 = pkgs.slurmSpankX11; # make X11 work in srun sessions

    ucx = callPackage ./ucx { };
  };

in pkgs-qc

