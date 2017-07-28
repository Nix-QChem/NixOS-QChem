pkgs: with pkgs; {
  molden = callPackage ./molden { };

  gamess = callPackage ./gamess { mathlib=atlas; };

  gamess-mkl = callPackage ./gamess { mathlib=callPackage ./mkl { } ; useMkl = true; };

  mkl = callPackage ./mkl { };
  
  impi = callPackage ./impi { };
  
  slurm17 = callPackage ./slurm { } ; # fixed version from the master branch
  slurmSpankX11 = callPackage ./slurm-spank-x11 { } ; # make X11 work in srun sessions 
}
