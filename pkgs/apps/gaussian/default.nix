{ lib
, stdenv
, buildFHSUserEnv
, symlinkJoin
, optpath
, version ? "16b01"
}:

let
  g16root = "${optpath}/gaussian/g${version}";

  buildEnv = exe: buildFHSUserEnv {
    name = exe;

    targetPkgs = pkgs: with pkgs; [ tcsh ];

    runScript = "${g16root}/${exe}";

    profile = ''
      export GAUSS_SCRDIR=$TMPDIR
      export g16root=${optpath}/gaussian
      source ${g16root}/bsd/g16.profile
    '';
  };

  executables = [ "g16" "formchk" "freqchk" "cubegen" "trajgen" "unfchk" "rwfdump" ];


in
symlinkJoin {
  name = "gaussian-${version}";
  paths = map buildEnv executables;
  meta = with lib; {
    description = "Quantum chemistry program package";
    license = licenses.unfree;
  };
}
