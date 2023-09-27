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
    ENVIRONMENTFILE=$(mktemp --suffix=.yml)
    cp ${src}/Environments/environment.yml $ENVIRONMENTFILE
    export GDMADIR=${gdma}/bin
    export PSI_SCRATCH="''${PSI_TMP:-$(mktemp -d)}"
    # Create conda environment only if not yet in existence
    {
      micromamba env list |& grep "$MAMBA_ROOT_PREFIX/envs/amoebamdpoltype" &> /dev/null
    } || {
      micromamba env create --yes -f $ENVIRONMENTFILE
    }
  '';

  runScript = "micromamba run -n amoebamdpoltype python ${src}/PoltypeModules/poltype.py";
}
