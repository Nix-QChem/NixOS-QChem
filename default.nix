pkgs: with pkgs; {
  molden = callPackage ./molden { };

  gamess = callPackage ./gamess { mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { mathlib=callPackage ./mkl { } ; useMkl = true; };
  
  octopus-minimal = callPackage ./octopus {};

  nwchem = callPackage ./nwchem { };

  arpackng = callPackage ./arpack-ng {};

  libxc = callPackage ./libxc {};

  mkl = callPackage ./mkl { };
  
  impi = callPackage ./impi { };
  
  slurm17 = callPackage ./slurm { } ; # fixed version from the master branch
  slurmSpankX11 = callPackage ./slurm-spank-x11 { } ; # make X11 work in srun sessions 
  
  beegfs = callPackage ./beegfs { };
  beegfs-module = callPackage ./beegfs/kernel-module.nix { kernel=pkgs.linux_4_9; };

}
