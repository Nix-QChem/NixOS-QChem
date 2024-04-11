{ lib
, stdenv
, buildFHSUserEnv
, symlinkJoin
, optpath
, version ? "16c02"
, g16Root ? "${optpath}/gaussian"
, g16Dir ? "${g16Root}/g${version}"
}:

let
  buildEnv = exe: buildFHSUserEnv {
    name = exe;

    targetPkgs = pkgs: with pkgs; [ tcsh ];

    runScript = "${g16Dir}/${exe}";

    profile = ''
      export GAUSS_SCRDIR=$TMPDIR
      export g16root=${g16Root}
      source ${g16Dir}/bsd/g16.profile
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
