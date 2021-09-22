let pkgs = import ./pkgs.nix;
in with pkgs; mkShell {
  buildInputs = [ qchem.python3.pkgs.xtb-python ];
}
