let
  # prefer 18.03-pre (master branch)
  pkgs = import (fetchTarball http://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {};

in with pkgs; {
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

#  arpackng = callPackage ./arpack-ng {};

#  libxc = callPackage ./libxc {};

  mkl = callPackage ./mkl { };

  impi = callPackage ./impi { };

#  slurm17 = callPackage ./slurm { } ; # fixed version from the master branch
#  slurmSpankX11 = callPackage ./slurm-spank-x11 { } ; # make X11 work in srun sessions

# beegfs = callPackage ./beegfs { };
# beegfs-module = callPackage ./beegfs/kernel-module.nix { kernel=pkgs.linux_4_9; };

}
