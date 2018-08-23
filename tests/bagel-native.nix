{ pkgs ? import <nixpkgs> {}, bagel ? pkgs.bagel } :

with import ../testing pkgs;


let
  # remove hf_read_mol_* from list since they expect
  # input from previous calculation
  files = pkgs.lib.remove "hf_read_mol_cart.json"
          (pkgs.lib.remove "hf_read_mol_sph.json"
          (pkgs.lib.mapAttrsToList (n: v: n)
          (pkgs.lib.filterAttrs (n: v: v=="regular" ) 
          (builtins.readDir "${bagel}/share/tests/" ))));

  tests = n: c: map (f: createTest {
     name = (baseNameOf f) + "-n${toString n}-n${toString c}";
     input = "${bagel}/share/tests/${f}";
     driver = ''
       export OMP_NUM_THREADS=${toString c}
       echo  '-np ${toString n}' $1
       bagel -np ${toString n} $1
     '';
     error = "ERROR";
    }) files;

in callTestList {
  name="bagel-native";
  buildInputs = [ bagel pkgs.openssh ];
  tests = (tests 1 1);
}
