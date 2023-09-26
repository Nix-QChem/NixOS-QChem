{ micromamba
, lib
, fetchFromGitHub
, buildFHSUserEnv
  # Runtime executable dependencies
, perl
, tinker
, psi4
, xtb
, gdma
, autodock-vina
}:

let
  pname = "poltype2";
  version = "unstable-2023-09-09";

  src = fetchFromGitHub {
    owner = "TinkerTools";
    repo = pname;
    rev = "3497187";
    hash = "sha256-Qu2g97zbdOZT6jsR2k+Xarfj9AKs252aLlgPi8JTd/8=";
  };

in
buildFHSUserEnv {
  name = "poltype";

  targetPkgs = pkgs: (with pkgs; [
    micromamba
    bashInteractive
    tinker
    xtb
    gdma
    autodock-vina
    perl
  ]);

  profile = ''
    unset PYTHONPATH
    eval "$(micromamba shell hook -s bash)"
    MAMBA="''${MAMBA_ROOT:-$(mktemp -d)}"
    export MAMBA_ROOT_PREFIX=$MAMBA/.mamba
    if [ -f $MAMBA/environment.yml ]; then
      chmod +w $MAMBA/environment.yml && rm $MAMBA/environment.yml
    fi
    cp ${src}/Environments/environment.yml $MAMBA/.
    export GDMADIR=${gdma}/bin
    export PSI_SCRATCH="''${PSI_TMP:-$(mktemp -d)}"
    micromamba env create --yes -f $MAMBA/environment.yml
  '';

  runScript = "micromamba run -n amoebamdpoltype python ${src}/PoltypeModules/poltype.py";
}
