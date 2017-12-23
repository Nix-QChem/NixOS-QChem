pkgs: with pkgs; {
  molden = callPackage ./molden { };

  gamess = callPackage ./gamess { mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { mathlib=callPackage ./mkl { } ; useMkl = true; };
  
  octopus-minimal = callPackage ./octopus {};

  nwchem = callPackage ./nwchem { };

  qdng = callPackage ./qdng { };

  arpackng = callPackage ./arpack-ng {};

  libxc = callPackage ./libxc {};

  mkl = callPackage ./mkl { };
  
  impi = callPackage ./impi { };
  
  slurm17 = callPackage ./slurm { } ; # fixed version from the master branch
  slurmSpankX11 = callPackage ./slurm-spank-x11 { } ; # make X11 work in srun sessions 
  
  beegfs = callPackage ./beegfs { };
  beegfs-opentk = callPackage ./beegfs/opentk.nix { };
  beegfs-utils = callPackage ./beegfs/utils.nix { };
  beegfs-meta = callPackage ./beegfs/meta.nix { };
  beegfs-mgmtd = callPackage ./beegfs/mgmtd.nix { };
  beegfs-storage = callPackage ./beegfs/storage.nix { };
  beegfs-helperd = callPackage ./beegfs/helperd.nix { };
  beegfs-module = callPackage ./beegfs/kernel-module.nix { kernel=pkgs.linux_4_9; };

}
