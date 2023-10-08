{ lib
, fetchFromGitHub
, buildFHSUserEnv
, gdma
, tinker
, autodock-vina
, enableGaussian ? false
, gaussian
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
    perl
    tcsh
  ]) ++ [
    tinker
    gdma
    autodock-vina
  ] ++ lib.optional enableGaussian gaussian;

  profile = ''
    # Mamba preparation
    unset PYTHONPATH
    eval "$(micromamba shell hook -s bash)"
    MAMBA="''${MAMBA_ROOT:-$(mktemp -d)}"
    export MAMBA_ROOT_PREFIX=$MAMBA/.mamba

    # Configure programmes not managed by Conda
    export GDMADIR=${gdma}/bin
    export PSI_SCRATCH="''${PSI_TMP:-$(mktemp -d)}"

    ${lib.strings.optionalString enableGaussian ''
    export GAUSS_SCRDIR="''${GAUSS_TMP:-$(mktemp -d)}"
    ''}

    # Setup "amoebamdpoltype" environment
    ENVIRONMENTFILE=$(mktemp --suffix=.yml)
    cp ${src}/Environments/environment.yml $ENVIRONMENTFILE
    {
      micromamba env list |& grep "$MAMBA_ROOT_PREFIX/envs/amoebamdpoltype" &> /dev/null
    } || {
      micromamba env create --yes -f $ENVIRONMENTFILE
    }

    # Setup "xtbenv" environment
    {
      micromamba env list |& grep "$MAMBA_ROOT_PREFIX/envs/xtbenv" &> /dev/null
    } || {
      micromamba env create --name xtbenv
      micromamba install -n xtbenv --yes -c conda-forge xtb=6.6.1
    }

    # Setup "ani" environment
    ENVIRONMENTFILE=$(mktemp --suffix=.yml)
    cp ${src}/Environments/ANI.yml $ENVIRONMENTFILE
    {
      micromamba env list |& grep "$MAMBA_ROOT_PREFIX/envs/ani" &> /dev/null
    } || {
      micromamba env create --yes -f $ENVIRONMENTFILE
    }
  '';

  runScript = "micromamba run -n amoebamdpoltype python ${src}/PoltypeModules/poltype.py";
}
