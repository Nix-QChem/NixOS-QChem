pkgs :

rec {
  testList = import ./tester.nix;

  callTestList = x : testList ({stdenv = pkgs.stdenv; lib=pkgs.lib; pkgs=pkgs; } // x);

  createTest = { name,
     # input file/parameter (will be $1 for driver)
     input ? "", 
     # test driver to run
     driver, 
     # desired result (grep regex)
     result ? null,
     # errrors (grep regex)
     error ? null,
     # define if output to be grep'd is not stdout
     outfile ? null } :
   {
     inherit name input driver result error outfile;
   };
}

