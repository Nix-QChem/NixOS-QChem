pkgs :

rec {
  testList = import ./tester.nix;
  callTestList = x : testList ({stdenv = pkgs.stdenv; lib=pkgs.lib; pkgs=pkgs; } // x);
  createTest = { name, input ? "", driver, result, outfile ? null } :
   {
     inherit name input driver result outfile;
   };
}

